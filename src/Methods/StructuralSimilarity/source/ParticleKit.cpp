//
// Created by Michael Heuer on 15.05.18.
//

#include "ParticleKit.h"

namespace ParticleKit {
    AtomKit atomKit = {};

    ElectronKit electronKit = {0, 0};

    void create(const AtomKit &atomKit, const ElectronKit &electronKit) {
        ParticleKit::atomKit = atomKit;

        ParticleKit::electronKit.first = electronKit.first;
        ParticleKit::electronKit.second = electronKit.second;
    }

    void create(const AtomKit &atomKit, int charge, unsigned multiplicity) {
        ParticleKit::atomKit = atomKit;

        createElectronKitFromAtomKit(atomKit, charge, multiplicity);
    }

    void create(const AtomsVector &atoms, int charge, unsigned multiplicity){
        createAtomKitFromAtomsVector(atoms);
        create(ParticleKit::atomKit, charge, multiplicity);
    }

    void create(const AtomsVector &atoms, const ElectronsVector &electrons) {
        createAtomKitFromAtomsVector(atoms);
        createElectronKitFromElectronsVector(electrons);
    }

    void create(const MolecularGeometry &molecularGeometry) {
        create(molecularGeometry.atoms(),molecularGeometry.electrons());
    }

    namespace {
        void createAtomKitFromAtomsVector(const AtomsVector &atoms) {

            AtomKit newAtomKit;
            std::vector<Elements::ElementType> elementsPresent;

            for (int i = 0; i < atoms.numberOfEntities(); ++i) {
                auto element = atoms[i].type();
                if (std::find(elementsPresent.begin(), elementsPresent.end(), element) == elementsPresent.end())
                    elementsPresent.emplace_back(element);
            }

            std::sort(elementsPresent.begin(), elementsPresent.end());

            for (const auto &element : elementsPresent) {
                newAtomKit.emplace_back<std::pair<Elements::ElementType, unsigned>>(
                        {element, atoms.typesVector().countOccurence(element)});
            }

            ParticleKit::atomKit = newAtomKit;
        };


        void createElectronKitFromElectronsVector(const ElectronsVector &electronsVector) {

            electronKit.first = electronsVector.typesVector().countOccurence(Spins::SpinType::alpha);
            electronKit.second = electronsVector.typesVector().countOccurence(Spins::SpinType::beta);
        }

        void createElectronKitFromAtomKit(const AtomKit &atomKit,
                                          int charge, unsigned multiplicity) {
            unsigned numberOfElectrons = 0;

            for (auto const &elemenTypeNumberPair : atomKit) {
                auto elementType = elemenTypeNumberPair.first;
                auto numberOfAtoms = elemenTypeNumberPair.second;

                numberOfElectrons += Elements::ElementInfo::Z(elementType) * numberOfAtoms;
            }
            numberOfElectrons -= charge;

            unsigned numberOfUnpairedElectrons = multiplicity - 1;

            assert((numberOfElectrons - numberOfUnpairedElectrons) % 2 == 0
                   && "The number of electron pairs must be a multiple of 2.");
            unsigned numberOfElectronPairs = (numberOfElectrons - numberOfUnpairedElectrons) / 2;

            // use amolqc convention
            unsigned numberOfAlphaElectrons = numberOfUnpairedElectrons + numberOfElectronPairs;
            unsigned numberOfBetaElectrons = numberOfElectronPairs;

            ParticleKit::electronKit.first = numberOfAlphaElectrons;
            ParticleKit::electronKit.second = numberOfBetaElectrons;
        };
    }

    bool isSubsetQ(const AtomsVector &atomsVector) {
        for (auto const &elemenTypeNumberPair : atomKit) {
            auto elementType = elemenTypeNumberPair.first;
            auto maxCount = elemenTypeNumberPair.second;

            if(atomsVector.typesVector().countOccurence(elementType) > maxCount)
                return false;
        }
        return true;
    }

    bool isSubsetQ(const ElectronsVector &electronsVector) {
        if(electronsVector.typesVector().countOccurence(Spins::SpinType::alpha) > ParticleKit::electronKit.first)
            return false;
        else if (electronsVector.typesVector().countOccurence(Spins::SpinType::beta) > ParticleKit::electronKit.second)
            return false;
        else
            return true;
    }

    bool isSubsetQ(const MolecularGeometry &molecularGeometry) {
        return isSubsetQ(molecularGeometry.atoms()) && isSubsetQ(molecularGeometry.electrons());
    }

    unsigned numberOfTypes() {
        return numberOfElementTypes() + numberOfSpinTypes();
    }

    unsigned numberOfAtoms() {
        unsigned sum = 0;

        for (auto const &elementTypeNumberPair :  atomKit)
            sum += elementTypeNumberPair.second;

        return sum;
    }

    unsigned numberOfElectrons() {
        return electronKit.first + electronKit.second;
    }

    unsigned numberOfParticles() {
        return numberOfAtoms()+numberOfElectrons();
    }


    unsigned numberOfElementTypes() {
        return unsigned(atomKit.size());
    }

    unsigned numberOfSpinTypes() {
        unsigned numberOfSpinTypes = 0;
        if(electronKit.first>0) // alpha
            numberOfSpinTypes +=1;
        if(electronKit.second>0) // beta
            numberOfSpinTypes +=1;

        return numberOfSpinTypes;
    }

    NumberedElement getNumberedElementByIndex(unsigned idx){
        assert(idx < numberOfAtoms());

        unsigned count = 0;
        for (auto& typeNumberPair : ParticleKit::atomKit) {
            if(idx >= count + typeNumberPair.second) {
                count += typeNumberPair.second;
            } else {
                return {typeNumberPair.first,idx-count};
            }
        }
    }

    NumberedSpin getNumberedSpinByIndex(unsigned idx) {
        assert(idx < numberOfElectrons());

        if( idx < electronKit.first)
            return {Spins::SpinType::alpha, idx};
        else
            return {Spins::SpinType::beta, idx-electronKit.first};
    }
}
