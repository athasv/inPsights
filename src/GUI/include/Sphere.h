//
// Created by heuer on 06.12.16.
//

#ifndef TEST_SPHERE_H
#define TEST_SPHERE_H

#include <Qt3DExtras/QSphereMesh>
#include "Abstract3dObject.h"

class Sphere : public Abstract3dObject{
  //Q_OBJECT
public:
    Sphere(Qt3DCore::QEntity *root, QColor color, const QVector3D location, const float radius);
    ~Sphere(){};

  float getRadius() const { return radius_;};

private:
    const float radius_;
    Qt3DExtras::QSphereMesh* mesh_;
};

#endif //TEST_SPHERE_H
