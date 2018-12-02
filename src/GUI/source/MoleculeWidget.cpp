//
// Created by Michael Heuer on 12.11.17.
//

#include <Qt3DRender>
#include <QtWidgets>
#include <MoleculeWidget.h>

#include <Metrics.h>
#include <Line3D.h>
#include <Bond3D.h>
#include <Cylinder.h>
#include <Particle3D.h>
#include <AtomsVectorLinkedElectronsVector.h>

MoleculeWidget::MoleculeWidget(QWidget *parent)
    :
    QWidget(parent),
    layout_(new QVBoxLayout(this)),
    qt3DWindow_(new Qt3DExtras::Qt3DWindow()),
    root_(new Qt3DCore::QEntity()),
    moleculeEntity_(new Qt3DCore::QEntity(root_)),
    cameraController_(new Qt3DExtras::QOrbitCameraController(root_)),
    infoText_(new QLabel("Info text")),
    atomsVector3D_(nullptr)
{
    setLayout(layout_);
    layout_->addWidget(createWindowContainer(qt3DWindow_));
    layout_->addWidget(infoText_);

    infoText_->setFixedHeight(14);

    qt3DWindow_->setRootEntity(root_);

    qt3DWindow_->camera()->lens()->setPerspectiveProjection(45.0f, 16.0f / 9.0f, 0.1f, 100.0f);
    qt3DWindow_->camera()->setPosition(QVector3D(2.5, -8, 0.0));
    qt3DWindow_->camera()->setViewCenter(QVector3D(0, 0, 0));

    cameraController_->setLinearSpeed(50.f);
    cameraController_->setLookSpeed(180.f);
    cameraController_->setCamera(qt3DWindow_->camera());

    //setToolTip(QString("Hey there"));
    //setMouseTracking(true);
}

Qt3DCore::QEntity* MoleculeWidget::getRoot() {
    return root_;
}

/*void MoleculeWidget::mouseMoveEvent(QMouseEvent *event) {
    std::cout << "MOUSE MOVEMENT" << std::endl;

    QWidget::mouseMoveEvent(event);  // Or whatever the base class is.
}*/



void MoleculeWidget::drawBonds() {
    auto bondDrawingLimit = float(1.40 * 1e-10 / AU::length); //arbitrary choosen

    for (auto it = atomsVector3D_->particles3D_.begin(); it != atomsVector3D_->particles3D_.end(); it++){
        for (auto jt = it+1; jt != atomsVector3D_->particles3D_.end(); jt++){
            auto distance = Metrics::distance((*it)->position(), (*jt)->position())
                            - (Elements::ElementInfo::vdwRadius((*it)->type())
                               + Elements::ElementInfo::vdwRadius((*jt)->type()))/10.0;

            if ( distance < bondDrawingLimit)
                new Bond3D(*(*it), *(*jt));
        }
    }
}

void MoleculeWidget::drawAtoms() {
    atomsVector3D_ = new AtomsVector3D(moleculeEntity_, *sharedAtomsVector_);
}

void MoleculeWidget::addElectronsVector(const ElectronsVector &electronsVector, int id) {
    activeElectronsVectorsMap_.emplace(id,new ElectronsVector3D(moleculeEntity_, electronsVector));
}

void MoleculeWidget::removeElectronsVector(int id) {
    activeElectronsVectorsMap_[id]->deleteLater();
    activeElectronsVectorsMap_.erase(id);
}

void MoleculeWidget::setSharedAtomsVector(AtomsVector atomsVector) {
    sharedAtomsVector_ = std::make_shared<AtomsVector >(std::move(atomsVector));
}

// TODO should be individually selectable for each list item
/*void drawSpinCorrelations() {
    for ( auto it = activeElectronsVectorsMap_.begin(); it != activeElectronsVectorsMap_.end(); it++ ){
        if(drawSpinCorrelations) {
            for (int i = 0; i < electrons.numberOfEntities(); ++i) {
                for (int j = i + 1; j < electrons.numberOfEntities(); ++j) {

                    auto corr = clusterData.SeeStats_.mean()(i,j);
                    if (std::abs(corr) >= spinCorrelationThreshold) {

                        QColor color;
                        if(corr > 0)
                            color = QColor::fromRgb(255,0,255);
                        else
                            color = QColor::fromRgb(0,255,0);

                        QVector3D start, end;
                        start.setX(electrons.positionsVector()[i].x()); //TODO use helper
                        start.setY(electrons.positionsVector()[i].y());
                        start.setZ(electrons.positionsVector()[i].z());
                        end.setX(electrons.positionsVector()[j].x());
                        end.setY(electrons.positionsVector()[j].y());
                        end.setZ(electrons.positionsVector()[j].z());

                        new Line3D(moleculeEntity_, color, {start, end}, std::abs(corr));
                    }
                }
            }
    }
}*/

void MoleculeWidget::drawConnections() {

    /*for (auto &mapItem : activeElectronsVectorsMap_) {
        auto electronsVector3D = mapItem.second;
        AtomsVectorLinkedElectronsVector linkedElectronsVector(
                sharedAtomsVector_,
                electronsVector3D);

        double coreThreshold = 0.1;
        double maxDistance = 1.6;

        auto valenceElectronIndices = linkedElectronsVector.valenceElectronsIndices(coreThreshold);

        for (auto it = valenceElectronIndices.begin(); it != valenceElectronIndices.end(); ++it) {
            for (auto jt = it + 1; jt != valenceElectronIndices.end(); ++jt) {
                auto e1 = linkedElectronsVector[*it];
                auto e2 = linkedElectronsVector[*jt];

                auto q1 = GuiHelper::toQVector3D(e1.position());
                auto q2 = GuiHelper::toQVector3D(e2.position());

                if (Metrics::distance(e1.position(), e2.position()) < maxDistance) {
                    if (e1.type() == e2.type())
                        if (e1.type() == Spin::alpha)
                            Cylinder(electronsVector3D, GuiHelper::QColorFromType<Spin>(Spin::alpha), {q1, q2}, 0.015,
                                     0.5);
                        else if (e1.type() == Spin::beta)
                            Cylinder(electronsVector3D, GuiHelper::QColorFromType<Spin>(Spin::beta), {q1, q2}, 0.015,
                                     0.5);
                        else
                            Cylinder(electronsVector3D, GuiHelper::QColorFromType<Spin>(Spin::none), {q1, q2}, 0.015,
                                     0.5);
                    else
                        Line3D(electronsVector3D, Qt::black, {q1, q2}, 0.25);
                }
            }
        }
    }*/
}