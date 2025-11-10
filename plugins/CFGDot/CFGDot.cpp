// CFGDot.cpp
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/raw_ostream.h"
#include <cstdlib>
#include <string>
#include <sstream>

using namespace llvm;

static std::string getDumpDir() {
  if (const char *Base = std::getenv("LLVM_EXAMPLES_OUTDIR"))
    return std::string(Base) + "/cfg";
  return "output/cfg";
}

namespace {

// Helper function to create a meaningful label for a basic block
static std::string getBasicBlockLabel(BasicBlock &BB, Function &F) {
  std::string Label;
  raw_string_ostream LabelStream(Label);

  // Start with the block name or index
  if (BB.hasName()) {
    LabelStream << BB.getName() << ":\\l";
  } else {
    // Get block index
    int idx = 0;
    for (BasicBlock &B : F) {
      if (&B == &BB) break;
      idx++;
    }

    // Special names for entry and exit blocks
    if (&BB == &F.getEntryBlock()) {
      LabelStream << "entry:\\l";
    } else {
      LabelStream << "BB" << idx << ":\\l";
    }
  }

  // Add first few instructions (excluding debug info)
  int instrCount = 0;
  const int maxInstructions = 3;  // Show first 3 instructions

  for (Instruction &I : BB) {
    // Skip debug instructions and lifetime markers
    if (isa<DbgInfoIntrinsic>(&I))
      continue;

    // Format the instruction
    std::string InstrStr;
    raw_string_ostream InstrStream(InstrStr);

    // For terminator instructions, show them specially
    if (I.isTerminator()) {
      if (auto *BI = dyn_cast<BranchInst>(&I)) {
        if (BI->isConditional()) {
          InstrStream << "br ";
          BI->getCondition()->printAsOperand(InstrStream, false);
          InstrStream << " ? ... : ...";
        } else {
          InstrStream << "br ...";
        }
      } else if (auto *RI = dyn_cast<ReturnInst>(&I)) {
        InstrStream << "ret";
        if (RI->getReturnValue()) {
          InstrStream << " ";
          RI->getReturnValue()->printAsOperand(InstrStream, false);
        }
      } else if (auto *SI = dyn_cast<SwitchInst>(&I)) {
        InstrStream << "switch ";
        SI->getCondition()->printAsOperand(InstrStream, false);
      } else if (isa<UnreachableInst>(&I)) {
        InstrStream << "unreachable";
      } else {
        InstrStream << I.getOpcodeName();
      }
      LabelStream << "  " << InstrStream.str() << "\\l";
      break;  // Terminator is always last
    }

    // For regular instructions, show a simplified form
    if (instrCount < maxInstructions) {
      // Show result if it has one
      if (!I.getType()->isVoidTy() && I.hasName()) {
        InstrStream << I.getName() << " = ";
      } else if (!I.getType()->isVoidTy()) {
        InstrStream << "%v = ";
      }

      // Show operation
      if (auto *BO = dyn_cast<BinaryOperator>(&I)) {
        InstrStream << BO->getOpcodeName();
      } else if (auto *CMP = dyn_cast<CmpInst>(&I)) {
        InstrStream << CMP->getOpcodeName() << " "
                    << CmpInst::getPredicateName(CMP->getPredicate());
      } else if (auto *PHI = dyn_cast<PHINode>(&I)) {
        InstrStream << "phi";
      } else if (auto *Call = dyn_cast<CallInst>(&I)) {
        if (Call->getCalledFunction() && Call->getCalledFunction()->hasName()) {
          InstrStream << "call @" << Call->getCalledFunction()->getName();
        } else {
          InstrStream << "call";
        }
      } else if (isa<AllocaInst>(&I)) {
        InstrStream << "alloca";
      } else if (isa<LoadInst>(&I)) {
        InstrStream << "load";
      } else if (isa<StoreInst>(&I)) {
        InstrStream << "store";
      } else if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
        InstrStream << "getelementptr";
      } else {
        InstrStream << I.getOpcodeName();
      }

      LabelStream << "  " << InstrStream.str() << "\\l";
      instrCount++;
    } else if (instrCount == maxInstructions) {
      // Get total instruction count
      int totalInstr = BB.size();
      if (totalInstr > maxInstructions + 1) {  // +1 for terminator
        LabelStream << "  ... (" << (totalInstr - maxInstructions - 1)
                    << " more)\\l";
      }
      instrCount++;
    }
  }

  return Label;
}

class CFGDotPass : public PassInfoMixin<CFGDotPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration())
      return PreservedAnalyses::all();

    // Ensure output dir exists
    std::string DumpDir = getDumpDir();
    std::error_code EC;
    sys::fs::create_directories(DumpDir);

    // One DOT per function
    std::string FileName = (DumpDir + "/" + F.getName().str() + ".dot");
    raw_fd_ostream OS(FileName, EC, sys::fs::OF_Text);
    if (EC) {
      errs() << "CFGDot: couldn't open " << FileName << ": " << EC.message() << "\n";
      return PreservedAnalyses::all();
    }

    OS << "digraph \"CFG of " << F.getName() << "\" {\n";

    // Graph attributes for better visualization
    OS << "  rankdir=TB;\n";  // Top to Bottom layout
    OS << "  node [shape=box, style=\"rounded,filled\", fillcolor=\"#add8e6\", "
       << "fontname=\"Courier\", fontsize=10];\n";
    OS << "  edge [fontname=\"Courier\", fontsize=9];\n";

    // Emit nodes with meaningful labels
    for (BasicBlock &BB : F) {
      std::string Label = getBasicBlockLabel(BB, F);

      // Special styling for entry and exit blocks
      if (&BB == &F.getEntryBlock()) {
        OS << "  \"" << &BB << "\" [label=\"" << Label
           << "\", fillcolor=\"#90ee90\", style=\"rounded,filled\", penwidth=2];\n";
      } else if (BB.getTerminator() && isa<ReturnInst>(BB.getTerminator())) {
        OS << "  \"" << &BB << "\" [label=\"" << Label
           << "\", fillcolor=\"#f08080\", style=\"rounded,filled\"];\n";
      } else {
        OS << "  \"" << &BB << "\" [label=\"" << Label << "\"];\n";
      }
    }

    // Emit edges with labels for conditional branches
    for (BasicBlock &BB : F) {
      Instruction *Term = BB.getTerminator();

      if (auto *BI = dyn_cast<BranchInst>(Term)) {
        if (BI->isConditional()) {
          // Conditional branch - label edges with T/F
          BasicBlock *TrueBB = BI->getSuccessor(0);
          BasicBlock *FalseBB = BI->getSuccessor(1);
          OS << "  \"" << &BB << "\" -> \"" << TrueBB
             << "\" [label=\"T\", color=green];\n";
          OS << "  \"" << &BB << "\" -> \"" << FalseBB
             << "\" [label=\"F\", color=red];\n";
        } else {
          // Unconditional branch
          OS << "  \"" << &BB << "\" -> \"" << BI->getSuccessor(0) << "\";\n";
        }
      } else if (auto *SI = dyn_cast<SwitchInst>(Term)) {
        // Switch instruction - label with case values
        for (auto Case : SI->cases()) {
          OS << "  \"" << &BB << "\" -> \"" << Case.getCaseSuccessor()
             << "\" [label=\"case " << Case.getCaseValue()->getValue() << "\"];\n";
        }
        // Default case
        OS << "  \"" << &BB << "\" -> \"" << SI->getDefaultDest()
           << "\" [label=\"default\"];\n";
      } else {
        // Other terminators
        for (BasicBlock *Succ : successors(&BB)) {
          OS << "  \"" << &BB << "\" -> \"" << Succ << "\";\n";
        }
      }
    }

    OS << "}\n";

    return PreservedAnalyses::all();
  }
};
} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
      LLVM_PLUGIN_API_VERSION, "CFGDot", LLVM_VERSION_STRING,
      [](PassBuilder &PB) {
        // Allow: -passes="function(cfg-dot)"
        PB.registerPipelineParsingCallback(
            [](StringRef Name, FunctionPassManager &FPM,
               ArrayRef<PassBuilder::PipelineElement>) {
              if (Name == "cfg-dot") {
                FPM.addPass(CFGDotPass());
                return true;
              }
              return false;
            });
      }};
}
