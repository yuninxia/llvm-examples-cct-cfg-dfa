// CCTInstrument.cpp
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {
class CCTInstrumentPass : public PassInfoMixin<CCTInstrumentPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
    if (F.isDeclaration())
      return PreservedAnalyses::all();

    Module *M = F.getParent();
    LLVMContext &Ctx = M->getContext();

    // Declare runtime hooks: void __cct_enter(const char*), __cct_exit(const char*)
    auto *VoidTy = Type::getVoidTy(Ctx);
    auto *CharPtrTy = Type::getInt8PtrTy(Ctx);
    FunctionCallee Enter = M->getOrInsertFunction(
        "__cct_enter", FunctionType::get(VoidTy, {CharPtrTy}, false));
    FunctionCallee Exit = M->getOrInsertFunction(
        "__cct_exit", FunctionType::get(VoidTy, {CharPtrTy}, false));

    // Create a global string pointer to this function's name once per function.
    IRBuilder<> B(&*F.getEntryBlock().getFirstInsertionPt());
    Value *FuncName = B.CreateGlobalStringPtr(F.getName());

    // Inject __cct_enter at the entry
    B.CreateCall(Enter, {FuncName});

    // Inject __cct_exit before each return
    for (BasicBlock &BB : F) {
      if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator())) {
        IRBuilder<> BR(RI);
        BR.CreateCall(Exit, {FuncName});
      }
    }

    // We changed the IR
    return PreservedAnalyses::none();
  }
};
} // namespace

// Pass plugin boilerplate
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
      LLVM_PLUGIN_API_VERSION, "CCTInstrument", LLVM_VERSION_STRING,
      [](PassBuilder &PB) {
        // Allow: -passes="function(cct-instrument)"
        PB.registerPipelineParsingCallback(
            [](StringRef Name, FunctionPassManager &FPM,
               ArrayRef<PassBuilder::PipelineElement>) {
              if (Name == "cct-instrument") {
                FPM.addPass(CCTInstrumentPass());
                return true;
              }
              return false;
            });
      }};
}
