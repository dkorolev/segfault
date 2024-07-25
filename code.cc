#include <iostream>
#include <thread>
#include <chrono>

void two() {
  std::cout << "two" << std::endl;
  std::this_thread::sleep_for(std::chrono::milliseconds(300));
}

void three() {
  std::cout << "and ..." << std::endl;
  std::this_thread::sleep_for(std::chrono::milliseconds(300));
}

void do_crash() {
  // __builtin_trap();
  *reinterpret_cast<int*>(0) = 42;
}

void crash() {
  std::cout << "... boom!" << std::endl;
  do_crash();
}

int main() {
  std::cout << "one" << std::endl;
  std::this_thread::sleep_for(std::chrono::milliseconds(300));
  two();
  three();
  crash();
}
