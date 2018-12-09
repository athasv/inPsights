//
// Created by heuer on 03.12.18.
//

#include <InPsightsWidget.h>
#include <QFileDialog>
#include <QString>

#include <QHBoxLayout>
#include <QGroupBox>
#include <QSpinBox>
#include <QSplashScreen>
#include <QTimer>
#include <QHeaderView>
#include "IntegerSortedTreeWidgetItem.h"
#include <iterator>
#include <vector>
#include <ParticlesVector.h>

InPsightsWidget::InPsightsWidget(QWidget *parent)
        :
        QWidget(parent),
        console(Logger::get()),
        moleculeWidget(new MoleculeWidget(this)),
        energyPartitioningWidget(new EnergyPartitioningWidget(this)), // TODO refator, should it be an additional window?
        atomsCheckBox(new QCheckBox("Atoms", this)),
        bondsCheckBox(new QCheckBox("Bonds", this)),
        spinConnectionsCheckBox(new QCheckBox("Spin Connections", this)),
        spinCorrelationsCheckBox(new QCheckBox("Spin Correlations", this)),
        spinCorrelationSlider(new QSlider(Qt::Orientation::Horizontal, this)),
        spinCorrelationSliderLabel(new QLabel(this)),
        maximaList(new QTreeWidget(this)) {

    loadData();
    showSplashScreen();
    createWidget();
    connectSignals();
    initialView();
    show();

}

void InPsightsWidget::createWidget() {
    setWindowTitle("inPsights - Chemical insights from |Ψ|².");
    auto gbox = new QGroupBox("Settings:");
    auto hbox = new QHBoxLayout(this);
    auto vboxOuter = new QVBoxLayout();
    auto vboxInner = new QVBoxLayout();
    auto sliderBox = new QHBoxLayout();

    setLayout(hbox);
    hbox->setStretch(0,3);
    hbox->setStretch(1,1);

    resize(1280, 800);
    hbox->addWidget(moleculeWidget, Qt::AlignLeft);
    hbox->addLayout(vboxOuter);


    // put into MaximaTreeWidget class
    auto headerLabels = QList<QString>({"ID", "N", "min(-ln(|Ψ|²))", "max(-ln(|Ψ|²))"});
    maximaList->setColumnCount(headerLabels.size());
    maximaList->setHeaderLabels(headerLabels);
    maximaList->header()->setStretchLastSection(false);

    vboxOuter->addWidget(maximaList);
    vboxOuter->addWidget(energyPartitioningWidget);
    vboxOuter->addWidget(gbox);
    gbox->setLayout(vboxInner);

    maximaList->setFixedWidth(350);
    maximaList->setSortingEnabled(true);

    auto checkboxGrid = new QGridLayout();
    vboxInner->addLayout(checkboxGrid);
    checkboxGrid->addWidget(atomsCheckBox,0,0);
    checkboxGrid->addWidget(bondsCheckBox,1,0);
    checkboxGrid->addWidget(spinConnectionsCheckBox,0,1);
    checkboxGrid->addWidget(spinCorrelationsCheckBox,1,1);

    vboxInner->addWidget(spinCorrelationSlider);
    vboxInner->addLayout(sliderBox);

    sliderBox->addWidget(spinCorrelationSliderLabel);
    sliderBox->addWidget(spinCorrelationSlider);

    setupSliderBox();
}

void InPsightsWidget::connectSignals() {
    connect(maximaList, SIGNAL(itemChanged(QTreeWidgetItem * , int)),
            this, SLOT(selectedStructure(QTreeWidgetItem * , int)));

    connect(atomsCheckBox, SIGNAL(stateChanged(int)),
            this, SLOT(onAtomsChecked(int)));

    connect(bondsCheckBox, SIGNAL(stateChanged(int)),
            this, SLOT(onBondsChecked(int)));

    connect(spinConnectionsCheckBox, SIGNAL(stateChanged(int)),
            this, SLOT(onSpinConnectionsChecked(int)));

    connect(spinCorrelationsCheckBox, SIGNAL(stateChanged(int)),
            this, SLOT(onSpinCorrelationsChecked(int)));

    connect(spinCorrelationSlider, SIGNAL(valueChanged(int)),
            this, SLOT(onSpinCorrelationsSliderChanged(int)));

    connect(energyPartitioningWidget, SIGNAL(atomsChecked(std::vector<int>)),
            moleculeWidget, SLOT(onAtomsChecked(std::vector<int>)));
    connect(energyPartitioningWidget, SIGNAL(electronsChecked(std::vector<int>)),
            moleculeWidget, SLOT(onElectronsChecked(std::vector<int>)));

    connect(energyPartitioningWidget, SIGNAL(atomsHighlighted(std::vector<int>)),
            moleculeWidget, SLOT(onAtomsHighlighted(std::vector<int>)));
    connect(energyPartitioningWidget, SIGNAL(electronsHighlighted(std::vector<int>)),
            moleculeWidget, SLOT(onElectronsHighlighted(std::vector<int>)));
}

void InPsightsWidget::setupSliderBox() {
    spinCorrelationSlider->setRange(0,100);
    spinCorrelationSlider->setSingleStep(1);
    spinCorrelationSlider->setValue(75);
    spinCorrelationSlider->setTickInterval(25);
    spinCorrelationSlider->setTickPosition(QSlider::TicksBelow);
}

void InPsightsWidget::selectedStructure(QTreeWidgetItem *item, int column) {
    auto maximaTreeWidgetItem = dynamic_cast<IntegerSortedTreeWidgetItem*>(item);

    if (column != 0)
        console->critical("Column 0 expected but got {} ", column);

    auto id = maximaTreeWidgetItem->data(0, Qt::ItemDataRole::UserRole).toList();
    auto clusterId = id[0].toInt();
    auto structureId = id[1].toInt();

    auto createQ = maximaTreeWidgetItem->checkState(0) == Qt::CheckState::Checked;
    console->info("Selected structure {1} from cluster {0} for {2}.", clusterId, structureId,
                  createQ ? "creation" : "deletion");

    if (createQ) {
        moleculeWidget->addElectronsVector(clusterCollection_[clusterId].exemplaricStructures_[structureId], clusterId, structureId);
        energyPartitioningWidget->updateData(clusterCollection_[clusterId]);
    } else
        moleculeWidget->removeElectronsVector(clusterId, structureId);
};

void InPsightsWidget::onAtomsChecked(int stateId) {
    moleculeWidget->drawAtoms(Qt::CheckState(stateId) == Qt::CheckState::Checked);
}

void InPsightsWidget::onBondsChecked(int stateId) {
    moleculeWidget->drawBonds(Qt::CheckState(stateId) == Qt::CheckState::Checked);
}

void InPsightsWidget::onSpinConnectionsChecked(int stateId) {
    moleculeWidget->drawSpinConnections(Qt::CheckState(stateId) == Qt::CheckState::Checked);
}

void InPsightsWidget::onSpinCorrelationsChecked(int stateId) {
    moleculeWidget->drawSpinCorrelations(Qt::CheckState(stateId) == Qt::CheckState::Checked,
                                         clusterCollection_,
                                         double(spinCorrelationSlider->value())/spinCorrelationSlider->maximum());
}

void InPsightsWidget::updateSpinCorrelationSliderLabel(int value) {
    auto corr = double(value)/spinCorrelationSlider->maximum();
    spinCorrelationSliderLabel->setText(QString::number(corr, 'f', 2));
}

void InPsightsWidget::onSpinCorrelationsSliderChanged(int value) {
    updateSpinCorrelationSliderLabel(value);
    if (spinCorrelationsCheckBox->checkState() == Qt::CheckState::Checked) {
        onSpinCorrelationsChecked(Qt::CheckState::Unchecked); //TODO ugly, create update() function in SpinCorrelation3D and make it accessible
        onSpinCorrelationsChecked(Qt::CheckState::Checked);
    }
}

void InPsightsWidget::showSplashScreen() {
    auto splashScreen = new QSplashScreen();

    splashScreen->setPixmap(QPixmap(":inPsights.png"));
    splashScreen->show();
    splashScreen->showMessage("Version 1.0.0", Qt::AlignRight, Qt::lightGray);

    splashScreen->finish(this);
}

void InPsightsWidget::loadData() {

    auto fileName = QFileDialog::getOpenFileName(this,
            QString("Open results file"),
            QDir::currentPath(),
            QString("YAML files (*.yml *.yaml *.json)"));

    moleculeWidget->infoText_->setText(fileName);

    YAML::Node doc = YAML::LoadFile(fileName.toStdString());
    auto nAtoms = doc["Atoms"].as<AtomsVector>().numberOfEntities();
    auto nElectrons = doc["Clusters"][0]["Structures"][0].as<ElectronsVector>().numberOfEntities();

    auto VnnStats = doc["Vnn"].as<IntraParticlesStatistics>();
    energyPartitioningWidget->setAtomEnergies(VnnStats);
    energyPartitioningWidget->initializeTreeItems(energyPartitioningWidget->atomsTreeWidget(),int(nAtoms));
    energyPartitioningWidget->initializeTreeItems(energyPartitioningWidget->electronsTreeWidget(),int(nElectrons));

    for (int clusterId = 0; clusterId < static_cast<int>(doc["Clusters"].size()); ++clusterId) {

        ClusterData clusterData = doc["Clusters"][clusterId].as<ClusterData>();

        clusterCollection_.emplace_back(clusterData);
        auto item = new IntegerSortedTreeWidgetItem(maximaList,{QString::number(clusterId),
                                                         QString::number(clusterData.N_),
                                                         QString::number(clusterData.valueStats_.cwiseMin()[0]),
                                                         QString::number(clusterData.valueStats_.cwiseMax()[0])});

        item->setCheckState(0, Qt::CheckState::Unchecked);

        QList<QVariant> id = {clusterId, 0};
        item->setData(0, Qt::ItemDataRole::UserRole, id);

        auto structures = doc["Clusters"][clusterId]["Structures"];

        for (int structureId = 1; structureId < static_cast<int>(structures.size()); ++structureId) {
            auto subItem = new IntegerSortedTreeWidgetItem(item, QStringList({QString::number(structureId)}));
            subItem->setCheckState(0, Qt::CheckState::Unchecked);

            id = {clusterId, structureId};
            subItem->setData(0, Qt::ItemDataRole::UserRole, id);
            item->addChild(subItem);
        }

        maximaList->addTopLevelItem(item);
        for (int i = 0; i < maximaList->columnCount(); ++i) {
            maximaList->resizeColumnToContents(i);
        }
        //maximaList->resize(maximaList->minimumSize());
    }
    moleculeWidget->setSharedAtomsVector(doc["Atoms"].as<AtomsVector>());
}

void InPsightsWidget::initialView() {
    maximaList->resizeColumnToContents(0);
    maximaList->resizeColumnToContents(1);
    maximaList->resizeColumnToContents(2);
    maximaList->resizeColumnToContents(3);
    maximaList->sortItems(0,Qt::SortOrder::AscendingOrder);
    atomsCheckBox->setCheckState(Qt::CheckState::Checked);
    bondsCheckBox->setCheckState(Qt::CheckState::Checked);
    maximaList->topLevelItem(0)->setCheckState(0, Qt::CheckState::Checked);
    spinConnectionsCheckBox->setCheckState(Qt::CheckState::Checked);
    spinCorrelationsCheckBox->setCheckState(Qt::CheckState::Checked);
    updateSpinCorrelationSliderLabel(spinCorrelationSlider->value());
}
