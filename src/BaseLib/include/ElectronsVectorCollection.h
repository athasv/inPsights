//
// Created by Michael Heuer on 30.10.17.
//

#ifndef AMOLQCGUI_ELECTRONCOLLECTIONPATH_H
#define AMOLQCGUI_ELECTRONCOLLECTIONPATH_H

#include "ParticlesVectorCollection.h"
#include "ElectronCollection.h"
#include "SpinTypesVector.h"

class ElectronsVectorCollection : public ParticlesVectorCollection{
public:
    ElectronsVectorCollection();
    explicit ElectronsVectorCollection(const SpinTypesVector& spinTypesVector);
    explicit ElectronsVectorCollection(const ElectronCollection& electronCollection);
    explicit ElectronsVectorCollection(const std::vector<ElectronCollection>& electronCollectionVector);
    explicit ElectronsVectorCollection(const PositionsVectorCollection& electronCollection);

    explicit ElectronsVectorCollection(const PositionsVectorCollection& electronCollection,
                                 const SpinTypesVector& spinTypesVector);

    ElectronCollection operator[](long i) const;

    const SpinTypesVector& spinTypesVector() const;
    SpinTypesVector& spinTypesVector();

    void insert (const ElectronCollection& electronCollection, long i);
    void append (const ElectronCollection& electronCollection);
    void prepend(const ElectronCollection& electronCollection);
    void permute(long i, long j) override;

private:
    SpinTypesVector spinTypesVector_;
};

#endif //AMOLQCGUI_ELECTRONCOLLECTIONPATH_H
