#include "application.h"

int main(int argc, char *argv[]) {
  Application app(argc, argv);

  return Application::exec();
}
