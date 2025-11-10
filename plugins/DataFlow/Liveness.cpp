// Liveness.cpp
// A tiny backward liveness analysis over LLVM IR (register values).
// Writes results to liveness/<function>.txt
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallBitVector.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Use.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/raw_ostream.h"
#include <cstdlib>
#include <string>

using namespace llvm;

static std::string getDumpDir() {
  if (const char *Base = std::getenv("LLVM_EXAMPLES_OUTDIR"))
    return std::string(Base) + "/liveness";
  return "output/liveness";
}

namespace {

static bool isDefinable(const Instruction &I) {
  return !I.getType()->isVoidTy();
}

class LivenessPass : public PassInfoMixin<LivenessPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration())
      return PreservedAnalyses::all();

    // Enumerate definable instructions -> indices
    SmallVector<Instruction *, 64> IdxToInst;
    DenseMap<const Instruction *, unsigned> InstToIdx;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (isDefinable(I)) {
          InstToIdx[&I] = (unsigned)IdxToInst.size();
          IdxToInst.push_back(&I);
        }
      }
    }
    const unsigned N = (unsigned)IdxToInst.size();

    // Per-BB bitvectors: def/use/in/out
    DenseMap<const BasicBlock *, SmallBitVector> Def, Use, In, Out;
    for (BasicBlock &BB : F) {
      SmallBitVector def(N, false), use(N, false);
      SmallBitVector seen(N, false); // defs seen so far in this block

      for (Instruction &I : BB) {
        // Uses: any operand that is a definable instruction not yet defined here
        for (llvm::Use &Op : I.operands()) {
          if (auto *OpI = dyn_cast<Instruction>(Op.get())) {
            auto It = InstToIdx.find(OpI);
            if (It != InstToIdx.end()) {
              unsigned idx = It->second;
              if (!seen.test(idx)) use.set(idx);
            }
          }
        }
        // Def: record after processing uses
        if (isDefinable(I)) {
          unsigned idx = InstToIdx[&I];
          def.set(idx);
          seen.set(idx);
        }
      }

      Def[&BB] = std::move(def);
      Use[&BB] = std::move(use);
      In[&BB]  = SmallBitVector(N, false);
      Out[&BB] = SmallBitVector(N, false);
    }

    // Iterative data-flow: In[B] = Use[B] U (Out[B] - Def[B]), Out[B] = U In[S]
    bool changed = true;
    while (changed) {
      changed = false;
      for (BasicBlock &BB : F) {
        SmallBitVector newOut(N, false);
        for (BasicBlock *Succ : successors(&BB)) {
          newOut |= In[Succ];
        }

        SmallBitVector newIn = Use[&BB];
        SmallBitVector temp = newOut;
        temp.reset(Def[&BB]); // i.e., temp = newOut - Def[B]
        newIn |= temp;

        if (newOut != Out[&BB]) { Out[&BB] = newOut; changed = true; }
        if (newIn != In[&BB])   { In[&BB]  = newIn;  changed = true; }
      }
    }

    // Write a plain-text report
    std::error_code EC;
    std::string DumpDir = getDumpDir();
    sys::fs::create_directories(DumpDir);
    std::string FileName = (DumpDir + "/" + F.getName().str() + ".txt");
    raw_fd_ostream OS(FileName, EC, sys::fs::OF_Text);
    if (EC) {
      errs() << "Liveness: couldn't open " << FileName << ": " << EC.message() << "\n";
      return PreservedAnalyses::all();
    }

    auto fmtSet = [&](const SmallBitVector &BV) {
      bool first = true;
      OS << "{";
      for (unsigned i = 0, e = N; i < e; ++i) {
        if (BV.test(i)) {
          if (!first) OS << ", ";
          first = false;
          const Instruction *I = IdxToInst[i];
          if (I->hasName())
            OS << "%" << I->getName();
          else
            OS << "%v" << i;
        }
      }
      OS << "}";
    };

    for (BasicBlock &BB : F) {
      OS << "BasicBlock " ;
      if (BB.hasName()) OS << BB.getName();
      else OS << (const void*)&BB;
      OS << ":\n  IN  = "; fmtSet(In[&BB]);  OS << "\n";
      OS << "  OUT = "; fmtSet(Out[&BB]); OS << "\n\n";
    }

    return PreservedAnalyses::all();
  }
};
} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
      LLVM_PLUGIN_API_VERSION, "Liveness", LLVM_VERSION_STRING,
      [](PassBuilder &PB) {
        // Allow: -passes="function(liveness)"
        PB.registerPipelineParsingCallback(
            [](StringRef Name, FunctionPassManager &FPM,
               ArrayRef<PassBuilder::PipelineElement>) {
              if (Name == "liveness") {
                FPM.addPass(LivenessPass());
                return true;
              }
              return false;
            });
      }};
}
