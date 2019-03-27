//
// Created by Michael Heuer on 2019-01-07.
//

#ifndef INPSIGHTS_ISOSURFACE_H
#define INPSIGHTS_ISOSURFACE_H

#include <Abstract3dObject.h>
#include <SurfaceMesh.h>

class SurfaceData;

class Surface : public Abstract3dObject{
public:
    Surface(Qt3DCore::QEntity *root,
            const SurfaceData& surfaceData,
            QColor color, float alpha = 1.0 );

private:
    SurfaceMesh * mesh_;
};

#endif //INPSIGHTS_ISOSURFACE_H
