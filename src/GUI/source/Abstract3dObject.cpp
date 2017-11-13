//
// Created by heuer on 06.12.16.
//

#include "Abstract3dObject.h"

#include <iostream>

Abstract3dObject::Abstract3dObject(Qt3DCore::QEntity *root, QColor color, const QVector3D location)
  : QEntity(root),
    color_(color),
    alpha_(1.0f),
    location_(location)
{

  entity = new Qt3DCore::QEntity(root);
  material = new Qt3DExtras::QPhongAlphaMaterial(root);
  transform = new Qt3DCore::QTransform;
  picker = new Qt3DRender::QObjectPicker;

  material->setSpecular(Qt::white);
  material->setShininess(0);
  material->setAmbient(color);
  material->setAlpha(1.0f);
  transform->setTranslation(location);

  entity->addComponent(transform);
  entity->addComponent(material);
  entity->addComponent(picker);

  connect(picker, &Qt3DRender::QObjectPicker::pressedChanged, this, &Abstract3dObject::onPressed);
}

void Abstract3dObject::setAlpha(float alpha) {
  alpha_ = alpha;
  material->setAlpha(alpha);
};

void Abstract3dObject::onPressed(bool pressed) {
  if (pressed) std::cout << "pressed" << std::endl;
  else std::cout << "not pressed" << std::endl;
}
