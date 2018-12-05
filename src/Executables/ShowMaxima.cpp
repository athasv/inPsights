//
// Created by Michael Heuer on 07.11.17.
//

#include <Serialization.h>
#include "RefFileImporter.h"
#include <MoleculeWidget.h>
#include <ParticlesVector3D.h>
#include <QApplication>
#include <iostream>
#include <exception>

bool handleCommandlineArguments(int argc, char **argv,
                                std::string &filename, unsigned &k, unsigned &m) {
    if (argc < 4) {
        std::cout << "Usage: \n"
                  << "Argument 1: reference filename (.ref)" << std::endl
                  << "Argument 2: k number" << std::endl
                  << "Argument 3: m number" << std::endl
                  << "max.ref 1 2" << std::endl;
        return false;
    } else if (argc == 4) {
        filename = argv[1];
        int kint = std::atoi(argv[2]);
        int mint = std::atoi(argv[3]);
        try {
            if (".ref" != filename.substr( filename.length() - 4 ))
                throw std::invalid_argument("Invalid file type '" + filename + "'.");
            if (kint < 1)
                throw std::invalid_argument("The k index must be a positive integer but is " + std::string(argv[2]));
            if (mint < 1)
                throw std::invalid_argument("The m index must be a positive integer but is " + std::string(argv[3]));
        }
        catch (std::invalid_argument &e){
            std::cout << e.what() << std::endl;
            abort();
        }

        k = unsigned(kint);
        m = unsigned(mint);
        return true;
    } else
        return false;
}

int main(int argc, char *argv[]) {
    std::string refFilename;
    unsigned k,m;

    if(!handleCommandlineArguments(argc, argv, refFilename,k,m)) return 0;

    RefFileImporter refFileImporter(refFilename);
    auto atoms = refFileImporter.getAtomsVector();
    auto electrons = refFileImporter.getMaximaStructure(k,m);

    QApplication app(argc, argv);
    setlocale(LC_NUMERIC,"C");

    auto moleculeWidget = new MoleculeWidget();
    moleculeWidget->setSharedAtomsVector(atoms);
    moleculeWidget->addElectronsVector(electrons);
    moleculeWidget->drawAtoms();
    moleculeWidget->drawBonds();
    moleculeWidget->drawSpinConnections();
    moleculeWidget->infoText_->setText(QString::fromStdString(refFilename));
    moleculeWidget->resize(1024,768);
    moleculeWidget->show();

    return app.exec();
};
