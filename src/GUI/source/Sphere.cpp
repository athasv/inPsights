#include <utility>

//
// Created by heuer on 06.12.16.
//

#include "Sphere.h"

Sphere::Sphere(Qt3DCore::QEntity *root, QColor color, const QVector3D location, const float radius)
  :
  Abstract3dObject(root, std::move(color), location),
  radius_(radius),
  mesh_(new Qt3DExtras::QSphereMesh(static_cast<Qt3DCore::QEntity*>(this))) {

  mesh_->setRadius(radius);
  mesh_->setRings(8);
  mesh_->setSlices(16);

  addComponent(mesh_);
}
