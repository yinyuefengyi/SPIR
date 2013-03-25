// Test the automatic pruning of module cache entries.
#ifdef IMPORT_DEPENDS_ON_MODULE
@import DependsOnModule;
#else
@import Module;
#endif

// We need 'touch' and 'find' for this test to work.
// REQUIRES: shell

// Clear out the module cache
// RUN: rm -rf %t
// Run Clang twice so we end up creating the timestamp file (the second time).
// RUN: %clang_cc1 -DIMPORT_DEPENDS_ON_MODULE -fmodules-ignore-macro=DIMPORT_DEPENDS_ON_MODULE -fmodules -F %S/Inputs -fmodules-cache-path=%t %s -verify
// RUN: %clang_cc1 -DIMPORT_DEPENDS_ON_MODULE -fmodules-ignore-macro=DIMPORT_DEPENDS_ON_MODULE -fmodules -F %S/Inputs -fmodules-cache-path=%t %s -verify
// RUN: ls %t | grep modules.timestamp
// RUN: ls -R %t | grep ^Module.pcm
// RUN: ls -R %t | grep DependsOnModule.pcm

// Set the timestamp back more than two days. We should try to prune,
// but nothing gets pruned because the module files are new enough.
// RUN: touch -m -a -A -481200 %t/modules.timestamp 
// RUN: %clang_cc1 -fmodules -F %S/Inputs -fmodules-cache-path=%t -fmodules -fmodules-prune-interval=172800 -fmodules-prune-after=345600 %s -verify
// RUN: ls %t | grep modules.timestamp
// RUN: ls -R %t | grep ^Module.pcm
// RUN: ls -R %t | grep DependsOnModule.pcm

// Set the DependsOnModule access time back more than four days.
// This shouldn't prune anything, because the timestamp has been updated, so
// the pruning mechanism won't fire.
// RUN: touch -a -A -961200 `find /Volumes/Data/dgregor/Projects/llvm-build-xcode/tools/clang/test/Modules/Output/prune.m.tmp -name DependsOnModule.pcm`
// RUN: %clang_cc1 -fmodules -F %S/Inputs -fmodules-cache-path=%t -fmodules -fmodules-prune-interval=172800 -fmodules-prune-after=345600 %s -verify
// RUN: ls %t | grep modules.timestamp
// RUN: ls -R %t | grep ^Module.pcm
// RUN: ls -R %t | grep DependsOnModule.pcm

// Set both timestamp and DependsOnModule.pcm back beyond the cutoff.
// This should trigger pruning, which will remove DependsOnModule but not Module.
// RUN: touch -m -a -A -481200 %t/modules.timestamp 
// RUN: touch -a -A -961200 `find /Volumes/Data/dgregor/Projects/llvm-build-xcode/tools/clang/test/Modules/Output/prune.m.tmp -name DependsOnModule.pcm`
// RUN: %clang_cc1 -fmodules -F %S/Inputs -fmodules-cache-path=%t -fmodules -fmodules-prune-interval=172800 -fmodules-prune-after=345600 %s -verify
// RUN: ls %t | grep modules.timestamp
// RUN: ls -R %t | grep ^Module.pcm
// RUN: ls -R %t | not grep DependsOnModule.pcm

// expected-no-diagnostics