#include <unordered_map>
#include <string>
#include <mutex>
#include <thread>
#include <iostream>
#include <atomic>

struct CCTNode {
  std::string name;
  std::atomic<size_t> count{0};
  std::unordered_map<std::string, CCTNode*> children;
  CCTNode *parent = nullptr;
  explicit CCTNode(std::string n, CCTNode *p=nullptr) : name(std::move(n)), parent(p) {}
};

static thread_local CCTNode *tls_current = nullptr;
static CCTNode *global_root = new CCTNode("(root)", nullptr);
static std::mutex global_mutex;

extern "C" void __cct_enter(const char *fn) {
  if (!fn) fn = "(unknown)";
  if (!tls_current) {
    // first time on this thread
    tls_current = global_root;
  }
  CCTNode *next = nullptr;
  {
    std::lock_guard<std::mutex> guard(global_mutex);
    auto it = tls_current->children.find(fn);
    if (it == tls_current->children.end()) {
      next = new CCTNode(fn, tls_current);
      tls_current->children.emplace(fn, next);
    } else {
      next = it->second;
    }
    next->count.fetch_add(1, std::memory_order_relaxed);
  }
  tls_current = next;
}

extern "C" void __cct_exit(const char * /*fn*/) {
  if (tls_current) {
    tls_current = tls_current->parent ? tls_current->parent : global_root;
  }
}

static void dump_node(const CCTNode *n, std::ostream &os, int depth) {
  for (int i = 0; i < depth; ++i) os << "  ";
  os << n->name << " [" << n->count.load(std::memory_order_relaxed) << "]\n";
  for (auto &kv : n->children) {
    dump_node(kv.second, os, depth + 1);
  }
}

static void cct_dump_all() {
  std::lock_guard<std::mutex> guard(global_mutex);
  std::cout << "=== Calling Context Tree ===\n";
  for (auto &kv : global_root->children) {
    dump_node(kv.second, std::cout, 0);
  }
}

// Ensure dump at process exit
struct CCTDumper {
  ~CCTDumper() { cct_dump_all(); }
} _cct_dumper;
