//
// Created by heuer on 06.12.16.
//

#ifndef AMOLQCPP_CYLINDER_H
#define AMOLQCPP_CYLINDER_H

#include <Qt3DExtras/QCylinderMesh>
#include "Abstract3dObject.h"

class Cylinder : public Abstract3dObject {

public:
  Cylinder(const Cylinder& cylinder);
  Cylinder(Qt3DCore::QEntity *root, QColor color,
           const std::pair<QVector3D, QVector3D>& pair,
           const float radius,
           const float alpha = 1.0f);

  ~Cylinder() {};

  float getRadius() const { return radius_; };

  void setRadius(const float radius) {
      radius_ = radius;
      mesh_->setRadius(radius);
  };

  float getLength() const { return length_; };
  QVector3D getStart() const{ return start_; };
  QVector3D getEnd() const{ return end_; };
  QVector3D getDifference() const{ return difference_; };

private:
  void rotateToOrientation(const QVector3D &orientation);

  float radius_, length_;
  QVector3D start_, end_, difference_;
  Qt3DExtras::QCylinderMesh *mesh_;
};

#endif //AMOLQCPP_CYLINDER_H
