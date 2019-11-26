/* Copyright (C) 2017-2019 Michael Heuer.
 *
 * This file is part of inPsights.
 * inPsights is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * inPsights is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with inPsights. If not, see <https://www.gnu.org/licenses/>.
 */

#include <QtWidgets>
#include <QScreen>
#include <MoleculeWidget.h>

#include <InPsightsWidget.h>
#include <Metrics.h>
#include <Line3D.h>
#include <Bond3D.h>
#include <ColorPalette.h>
#include <Surface.h>
#include <SurfaceDataGenerator.h>
#include <QuickHull.h>
#include <Conversion.h>
#include <SpinCorrelations3D.h>
#include <spdlog/spdlog.h>
#include <X3domConverter.h>

MoleculeWidget::MoleculeWidget(QWidget *parent)
        :
        QWidget(parent),
        qt3DWindow_(new Qt3DExtras::Qt3DWindow()),
        root_(new Qt3DCore::QEntity()),
        moleculeEntity_(new Qt3DCore::QEntity(root_)),
        cameraController_(new Qt3DExtras::QOrbitCameraController(root_)),
        screenshotButton_(new QPushButton("Save image", this)),
        x3dExportButton_(new QPushButton("Save x3d", this)),
        pan_(new QSpinBox(this)),
        tilt_(new QSpinBox(this)),
        roll_(new QSpinBox(this)),
        defaultCameraDistance_(8.0f),
        fileInfoText_(new QLabel("Info text")),
        panTiltRollText_(new QLabel("pan/tilt/roll")),
        atomsVector3D_(nullptr),
        cartesianAxes_(nullptr){

    auto outerLayout = new QVBoxLayout(this);
    auto innerLayout = new QHBoxLayout();

    setLayout(outerLayout);
    outerLayout->addWidget(createWindowContainer(qt3DWindow_),1);
    outerLayout->addLayout(innerLayout,0);
    innerLayout->addWidget(screenshotButton_,2);
    innerLayout->addWidget(x3dExportButton_,2);
    innerLayout->addWidget(fileInfoText_, 5);
    innerLayout->addWidget(panTiltRollText_,1);
    innerLayout->addWidget(pan_,1);
    innerLayout->addWidget(tilt_,1);
    innerLayout->addWidget(roll_,1);

    qt3DWindow_->setRootEntity(root_);

    connect(screenshotButton_, &QPushButton::clicked, this, &MoleculeWidget::onScreenshot);
    connect(x3dExportButton_, &QPushButton::clicked, this, &MoleculeWidget::onX3dExport);

    connect(pan_, qOverload<int>(&QSpinBox::valueChanged),
            this, &MoleculeWidget::onCameraSpinBoxesChanged);
    connect(tilt_, qOverload<int>(&QSpinBox::valueChanged),
            this, &MoleculeWidget::onCameraSpinBoxesChanged);
    connect(roll_, qOverload<int>(&QSpinBox::valueChanged),
            this, &MoleculeWidget::onCameraSpinBoxesChanged);

    initialCameraSetup();
    setMouseTracking(true);
}

void MoleculeWidget::onCameraSpinBoxesChanged(int) {
    defaultCameraView();
    qt3DWindow_->camera()->panAboutViewCenter(float(pan_->value()));
    qt3DWindow_->camera()->tiltAboutViewCenter(float(tilt_->value()));
    qt3DWindow_->camera()->rollAboutViewCenter(float(roll_->value()));
}

Qt3DCore::QEntity *MoleculeWidget::getMoleculeEntity() {
    return moleculeEntity_;
}

void MoleculeWidget::setupSpinBoxes(float pan, float tilt, float roll) {
    pan_->setRange(-180,180);
    pan_->setSingleStep(5);
    pan_->setValue(static_cast<int>(pan));
    pan_->setSuffix("°");

    tilt_->setRange(-180,180);
    tilt_->setSingleStep(5);
    tilt_->setValue(static_cast<int>(tilt));
    tilt_->setSuffix("°");

    roll_->setRange(-180,180);
    roll_->setSingleStep(5);
    roll_->setValue(static_cast<int>(roll));
    roll_->setSuffix("°");
}

void MoleculeWidget::initialCameraSetup(float distance, float pan, float tilt, float roll) {
    defaultCameraDistance_ = distance;
    setupSpinBoxes(pan, tilt, roll);

    cameraController_->setLinearSpeed(50.f);
    cameraController_->setLookSpeed(180.f);

    cameraController_->setCamera(qt3DWindow_->camera());
    defaultCameraView();
    onCameraSpinBoxesChanged(0);
}

void MoleculeWidget::defaultCameraView() {
    qt3DWindow_->camera()->setViewCenter({0,0,0});
    qt3DWindow_->camera()->setUpVector({1,0,0});
    qt3DWindow_->camera()->setPosition({0,1,0});
    qt3DWindow_->camera()->viewSphere({0, 0, 0}, defaultCameraDistance_);
}

void MoleculeWidget::drawAxes(bool drawQ) {
    if (drawQ) {
        cartesianAxes_ = new CartesianAxes(moleculeEntity_);
    } else {
        cartesianAxes_->deleteLater();
        delete cartesianAxes_;
    }
}

void MoleculeWidget::drawAtoms(bool drawQ) {
    if (drawQ) {
        atomsVector3D_ = new AtomsVector3D(moleculeEntity_, *sharedAtomsVector_);
    } else {
        atomsVector3D_->deleteConnections();
        atomsVector3D_->deleteLater();
        delete atomsVector3D_;
    }
}

void MoleculeWidget::drawBonds(bool drawQ) {
    if (atomsVector3D_) {
        if (drawQ)
            atomsVector3D_->drawConnections();
        else
            atomsVector3D_->deleteConnections();
    }
}

void MoleculeWidget::drawSpinConnections(bool drawQ) {
    if (drawQ)
        for (auto &cluster : activeElectronsVectorsMap_)
            for (auto &structure : cluster.second)
                structure.second->drawConnections();
    else
        for (auto &cluster : activeElectronsVectorsMap_)
            for (auto &structure : cluster.second)
                structure.second->deleteConnections();
}

void MoleculeWidget::addElectronsVector(const ElectronsVector &electronsVector, int clusterId, int structureId, bool coloredQ) {
    activeElectronsVectorsMap_[clusterId][structureId] = new ElectronsVector3D(moleculeEntity_, electronsVector, coloredQ);
}

void MoleculeWidget::removeElectronsVector(int clusterId, int structureId) {
    activeElectronsVectorsMap_[clusterId][structureId]->deleteLater();
    activeElectronsVectorsMap_[clusterId].erase(structureId);

    if(activeElectronsVectorsMap_[clusterId].empty()) {
        activeElectronsVectorsMap_.erase(clusterId);
    }
}

void MoleculeWidget::setSharedAtomsVector(AtomsVector atomsVector) {
    sharedAtomsVector_ = std::make_shared<AtomsVector>(std::move(atomsVector));
}

void MoleculeWidget::addSeds(int clusterId, const std::vector<ClusterData> &clusterData, double includedPercentage) {
    auto spins = clusterData[clusterId].representativeStructure().typesVector();
    auto N = spins.numberOfEntities();

    std::vector<Surface*> seds(N);

    const auto& voxelData = clusterData[clusterId].voxelCubes_;

    for (long i = 0; i < spins.numberOfEntities(); ++i) {
        SurfaceDataGenerator surfaceDataGenerator(voxelData[i]);
        auto surfaceData = surfaceDataGenerator.computeSurfaceData(includedPercentage);
        seds[i] = new Surface(getMoleculeEntity(), surfaceData, GuiHelper::QColorFromType(spins[i]), 0.15);
    }
    activeSedsMap_[clusterId] = seds;
}

void MoleculeWidget::removeSeds(int clusterId) {
    for (auto &sed : activeSedsMap_[clusterId])
        sed->deleteLater();

    if (!activeSedsMap_[clusterId].empty())
        activeSedsMap_.erase(clusterId);
}


void MoleculeWidget::drawSpinCorrelations(bool drawQ,
                                          const std::vector<ClusterData> &clusterData,
                                          double spinCorrelationThreshold, bool drawSameSpinCorrelationsQ) {
    //TODO SPLIT INTO DRAW AND DELETE METHODS
    for (auto &cluster : activeElectronsVectorsMap_)
        for (auto &structure : cluster.second) {
            if (drawQ) {
                new SpinCorrelations3D(structure.second, clusterData[cluster.first].SeeStats_, spinCorrelationThreshold, drawSameSpinCorrelationsQ);
            } else {
                structure.second->deleteCorrelations();
            }
        }
}

void MoleculeWidget::onAtomsChecked(std::vector<int> selectedParticles) {
    auto &particles = atomsVector3D_->particles3D_;

    for (int i = 0; i < static_cast<int>(particles.size()); ++i) {
        auto foundQ = std::find(selectedParticles.begin(), selectedParticles.end(), i) != selectedParticles.end();
        particles[i]->onSelected(foundQ);
    }
}

void MoleculeWidget::onAtomsHighlighted(std::vector<int> selectedParticles) {
    auto &particles = atomsVector3D_->particles3D_;

    for (int i = 0; i < static_cast<int>(particles.size()); ++i) {
        auto foundQ = std::find(selectedParticles.begin(), selectedParticles.end(), i) != selectedParticles.end();
        particles[i]->onHighlighted(foundQ); //TODO add highlight, select and normal function
    }
}


void MoleculeWidget::onElectronsChecked(std::vector<int> selectedParticles) {
    auto &particles = activeElectronsVectorsMap_.begin()->second.begin()->second->particles3D_;

    for (int i = 0; i < static_cast<int>(particles.size()); ++i) {
        auto foundQ = std::find(selectedParticles.begin(), selectedParticles.end(), i) != selectedParticles.end();
        particles[i]->onSelected(foundQ);
    }

}

void MoleculeWidget::onElectronsHighlighted(std::vector<int> selectedParticles) {
    auto &particles = activeElectronsVectorsMap_.begin()->second.begin()->second->particles3D_;
    for (int i = 0; i < static_cast<int>(particles.size()); ++i) {
        auto foundQ = std::find(selectedParticles.begin(), selectedParticles.end(), i) != selectedParticles.end();
        particles[i]->onHighlighted(foundQ);
    }
}

void MoleculeWidget::addMaximaHulls(int clusterId, const std::vector<ClusterData> &clusterData) {
    auto spins = clusterData[clusterId].representativeStructure().typesVector();
    auto N = spins.numberOfEntities();

    std::vector<Surface*> maximaHulls(N);

    quickhull::QuickHull<float> qh;

    for (long i = 0; i < spins.numberOfEntities(); ++i) {
        std::vector<Eigen::Vector3f> electronPointCloud;
        for(const auto & ev : clusterData[clusterId].exemplaricStructures_)
            electronPointCloud.emplace_back(ev[i].position().cast<float>());

        auto hull = qh.getConvexHull(electronPointCloud);
        auto vertices = hull.getVertices();
        auto triangles = hull.getTriangles();

        Conversion::calculateVertexNormals(vertices, triangles);
        SurfaceData surfaceData;
        surfaceData.triangles = triangles;
        surfaceData.vertices = vertices;

        maximaHulls[i] = new Surface(getMoleculeEntity(), surfaceData, ColorPalette::colorFunction(i), 0.5);
    }
    activeMaximaHullsMap_[clusterId] = maximaHulls;
}

void MoleculeWidget::removeMaximaHulls(int clusterId) {
    for (auto &hull : activeMaximaHullsMap_[clusterId])
        hull->deleteLater();

    if (!activeMaximaHullsMap_[clusterId].empty())
        activeMaximaHullsMap_.erase(clusterId);
}

void MoleculeWidget::onScreenshot(bool) {
    QScreen *screen = QGuiApplication::primaryScreen();
    if (const QWindow *window = windowHandle())
        screen = window->screen();
    if (!screen)
        return;
    std::string name = createFilenameFromActiveElectronvectors() + ".png";

    QFile file(name.c_str());
    file.open(QIODevice::WriteOnly);
    screen->grabWindow(qt3DWindow_->winId()).save(&file, "PNG");
    file.close();
}

std::string MoleculeWidget::createFilenameFromActiveElectronvectors() const {
    std::string name;

    // if  the inPsightsWidget is the parent
    auto inPsightsWidget = dynamic_cast<InPsightsWidget*>(parent());
    if(inPsightsWidget) {
        name = inPsightsWidget->filenameWithoutExtension().c_str();

        for (auto [key, submap] : activeElectronsVectorsMap_) {
            name += "-";
            name += std::to_string(key);
            name += "-[";
            if(inPsightsWidget->plotAllActiveQ()){
                name  += "all]";
            } else {
                for (auto[subkey, value] : submap) {
                    name += std::to_string(subkey);
                    name += ",";
                }
                name = name.substr(0, name.size() - 1);
                name += "]";
            }
        }
    } else {
        name = QDateTime::currentDateTime().toString(Qt::ISODate).toStdString();
    }
    return name;
}


void MoleculeWidget::onX3dExport(bool) {

    auto filename = createFilenameFromActiveElectronvectors() + ".html";

    X3domConverter x3Dconverter(filename, filename, "");
    auto atoms3d = atomsVector3D_->particles3D_;

    for (const auto & a : atoms3d) {
        x3Dconverter.addSphere(a.operator*(),2);
    }

    //TODO Refactor
    double bondDrawingLimit = 1.40 * 1e-10 / AU::length;
    for (long i = 0; i < atomsVector3D_->numberOfEntities(); ++i) {
        for (long j = i+1; j < atomsVector3D_->numberOfEntities(); ++j) {

            auto atomDistance = Metrics::distance(
                    atomsVector3D_->operator[](i).position(),
                    atomsVector3D_->operator[](j).position());
            auto addedGuiRadii = (GuiHelper::radiusFromType(atomsVector3D_->operator[](i).type())
                                  + GuiHelper::radiusFromType(atomsVector3D_->operator[](j).type()));


            if (atomDistance - 0.5*addedGuiRadii < bondDrawingLimit) {
                Qt3DCore::QEntity root;
                Bond3D bond(&root, *atomsVector3D_->particles3D_[i], *atomsVector3D_->particles3D_[j]);
                x3Dconverter.addCylinder(*bond.srcCylinder_,2);
                x3Dconverter.addCylinder(*bond.destCylinder_,2);
            }
        }
    }

    for(const auto& evMap : activeElectronsVectorsMap_){
        Qt3DCore::QEntity root;

        for(const auto& ev : evMap.second) {
            for (const auto &e : ev.second->particles3D_) {
                x3Dconverter.addSphere(e.operator*(),1);
            }
        }
    }

    x3Dconverter.closeScene();
}
