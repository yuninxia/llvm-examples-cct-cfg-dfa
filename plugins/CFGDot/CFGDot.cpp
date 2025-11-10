// CFGDot.cpp
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
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
    return std::string(Base) + "/cfg";
  return "output/cfg";
}

namespace {
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
    // Emit nodes
    for (BasicBlock &BB : F) {
      OS << "  \"" << &BB << "\" [label=\"";
      if (BB.hasName()) OS << BB.getName();
      else OS << "bb";
      OS << "\"];\n";
    }
    // Emit edges
    for (BasicBlock &BB : F) {
      for (BasicBlock *Succ : successors(&BB)) {
        OS << "  \"" << &BB << "\" -> \"" << Succ << "\";\n";
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
