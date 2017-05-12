#include <iostream>
#include <Eigen/Core>
#include <QGuiApplication>
#include <Qt3DCore>
#include <Qt3DRender>
#include <Qt3DExtras>

#include "ElementInfo.h"
#include "ElementTypes.h"
#include "Sphere.h"
#include "Cylinder.h"
#include "DividedCylinder.h"
#include "Atom.h"
#include "Bond.h"
#include "Electron.h"
#include "Polyline.h"

#include "BSpline.h"
#include "BSplinePlotter.h"
#include "StringMethod.h"


Qt3DCore::QEntity *createTestScene() {

  Eigen::VectorXd xA(2 * 3);
  Eigen::VectorXd xB(2 * 3);
  xA << 0.0, 0.0, 0.70014273,  0.0, 0.00, -0.70014273;
  xB << 0.0, 0.0, -0.70014273, 0.0, 0.00, +0.70014273;

  unsigned numberOfStates = 7;
  Eigen::MatrixXd initialCoordinates(2 * 3, numberOfStates);

  Eigen::VectorXd delta = xB - xA;
  for (int i = 0; i < numberOfStates; ++i) {
    double rel = double(i) / double(numberOfStates - 1);

    Eigen::VectorXd randVec(2*3);
    if ( i == 0  || i == (numberOfStates-1)) randVec.setZero();
    else randVec.setRandom();

    randVec *= 0.5;

    initialCoordinates.col(i) = xA + ((delta+randVec) * rel);
  }

  StringMethod stringMethod(initialCoordinates);
  std::cout << stringMethod.getChain().coordinates() << std::endl;
  //stringMethod.optimizeString();


  Qt3DCore::QEntity *root = new Qt3DCore::QEntity();

  Atom H1(root, QVector3D(0.f,0.f,+0.70014273f), Elements::ElementType::C);
  Atom H2(root, QVector3D(0.f,0.f,-0.70014273f), Elements::ElementType::C);
  //Bond b1(H1, H2);

  BSplinePlotter bSplinePlotter(root, stringMethod.getArcLengthParametrizedBSpline(), 50, 0.005f);

  //Sphere s0(root, Qt::black, QVector3D(0, 0, 0), 0.5f);
  //Cylinder x(root, Qt::red, {QVector3D(0, 0, 0), QVector3D(20, 0, 0)}, .25f);
  //Cylinder y(root, Qt::green, {QVector3D(0, 0, 0), QVector3D(0, 20, 0)}, .25f);
  //Cylinder z(root, Qt::blue, {QVector3D(0, 0, 0), QVector3D(0, 0, 20)}, .25f);

  //Electron e1(root, QVector3D(12.0f, 1.0f, 7.0f), Spin::SpinType::Alpha);
  //Electron e2(root, QVector3D(9.0f, 1.2f, 7.0f), Spin::SpinType::Beta);
  //Bond b1(N, O);
  //Bond b2(C, O);

  //Qt3DRender::QObjectPicker(); // emits signals for you to handle
  //Qt3DRender::QPickingSettings* pickingSettings = new Qt3DRender::QPickingSettings();
  //pickingSettings->setPickMethod(Qt3DRender::QPickingSettings::PickMethod::BoundingVolumePicking);

  return root;
}


int main(int argc, char *argv[]) {

  BSplines::BSpline bs;

  QGuiApplication app(argc, argv);

  Qt3DExtras::Qt3DWindow view;
  Qt3DCore::QEntity *scene = createTestScene();

  // camera
  Qt3DRender::QCamera *camera = view.camera();
  camera->lens()->setPerspectiveProjection(45.0f, 16.0f / 9.0f, 0.1f, 100.0f);
  camera->setPosition(QVector3D(0, 0, 2.0));
  camera->setViewCenter(QVector3D(0, 0, 0));
  //camera->setFarPlane(1000);
  //camera->setNearPlane(0.1);

  // manipulator
  //Qt3DExtras::QFirstPersonCameraController* manipulator = new Qt3DExtras::QFirstPersonCameraController(scene);
  Qt3DExtras::QOrbitCameraController *manipulator = new Qt3DExtras::QOrbitCameraController(scene);
  manipulator->setLinearSpeed(50.f);
  manipulator->setLookSpeed(180.f);
  manipulator->setCamera(camera);


  view.setRootEntity(scene);

  view.show();

  return app.exec();


}
