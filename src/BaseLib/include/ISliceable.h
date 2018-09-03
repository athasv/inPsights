//
// Created by Michael Heuer on 31.08.18.
//

#ifndef AMOLQCPP_ISLICEABLE_H
#define AMOLQCPP_ISLICEABLE_H

#include "AbstractVector.h"
#include "ReturnAndReset.h"
#include "Interval.h"
#include <memory>
#include <Eigen/Core>


template<typename Scalar>
class ISliceable : public AbstractVector {
protected:

    using VectorType = Eigen::Matrix<Scalar, Eigen::Dynamic,1>;
    using RefVectorType = Eigen::Ref<VectorType>;

public:

    ISliceable(long numberOfEntities = 0, long entityLength = 1)
    :
    AbstractVector(numberOfEntities, entityLength),
    data_(VectorType::Constant(numberOfEntities, 0)),
    resetType_(Reset::Automatic),
    sliceInterval_({0, numberOfEntities}),
    refPtr_()
    {
        resetRef();
    }

    ISliceable(const ISliceable &rhs)
    :
    AbstractVector(rhs.numberOfEntities(), rhs.entityLength()),
    data_(rhs.asEigenVector()),
    resetType_(Reset::Automatic),
    sliceInterval_({0, rhs.numberOfEntities()}), //TODO CAREFUL * ENTITYLENGTH?
    refPtr_()
    {
        resetRef();
    }

    ISliceable &operator=(const ISliceable &rhs) {
        if (this == &rhs) {
            resetRef();
            return *this;
        }
        AbstractVector::setEntityLength(rhs.entityLength());
        AbstractVector::setNumberOfEntities(rhs.numberOfEntities());
        data_ = rhs.asEigenVector();
        resetRef();

        return *this;
    }

    std::unique_ptr<RefVectorType> makeAllRefPtr(){
        return std::make_unique<RefVectorType>(data_.segment(0,numberOfEntities()*entityLength()));
    }
    std::unique_ptr<RefVectorType> makeRefPtr(const Interval& interval){
        return std::make_unique<RefVectorType>(
                data_.segment(
                        calculateIndex(interval.start()),
                        interval.numberOfEntities()*entityLength())
                );
    }

    void resetRef() {
        resetType_ = Reset::Automatic;
        sliceInterval_ = {0, numberOfEntities()};
        refPtr_.reset();
        refPtr_ = makeAllRefPtr();
    }

    void slice(const Interval& interval, const Reset& resetType = Reset::Automatic) {
        assert(interval.numberOfEntities() <= numberOfEntities() && "The interval is too long.");
        resetType_ = resetType;
        sliceInterval_ = interval;
        refPtr_.reset();
        refPtr_ = makeRefPtr(interval);
    }

    void entity(long i, const Reset& resetType = Reset::Automatic) {
        return slice(Interval(i), resetType);
    }


    void resetStrategy(const Usage &usage) {
        if( resetType_ == Reset::Automatic
            || (resetType_ == Reset::OnFinished && usage == Usage::Finished))
            resetRef();
    }

    void permute(const Eigen::PermutationMatrix<Eigen::Dynamic> &permutation) override {
        permuteMethod(permutation);
        resetRef();
    }

    void permute(const Eigen::PermutationMatrix<Eigen::Dynamic> &permutation, const Usage &usage) {
        permuteMethod(permutation);
        resetStrategy(usage);
    }

    void permuteMethod(const Eigen::PermutationMatrix<Eigen::Dynamic> &permutation) {
        assert(permutation.indices().size() == sliceInterval_.numberOfEntities()
               && "The permutation vector length must be equal to the number of entities");

        auto tmp = resetType_;
        resetType_ = Reset::OnFinished;

        if(entityLength() > 1) {
            dataRef(Usage::NotFinished) =  adaptedToEntityLength(permutation) * dataRef(Usage::NotFinished);
        }
        else
            dataRef(Usage::NotFinished) = permutation* dataRef(Usage::NotFinished);

        resetType_ = tmp;
    }

    Eigen::PermutationMatrix<Eigen::Dynamic> adaptedToEntityLength(
            const Eigen::PermutationMatrix<Eigen::Dynamic> &permutation){

        Eigen::VectorXi raw(permutation.indices().size()*entityLength());

        for (int i = 0; i < permutation.indices().size(); ++i) {
            auto originIdx = i*entityLength();
            auto targetIdx = permutation.indices()[i]*entityLength();

            raw[originIdx+0] = targetIdx+0;
            raw[originIdx+1] = targetIdx+1;
            raw[originIdx+2] = targetIdx+2;
        }
        return Eigen::PermutationMatrix<Eigen::Dynamic>(raw);
    }

    const VectorType& asEigenVector() const {
        return data_;
    }

    VectorType& asEigenVector() {
        return data_;
    }

    RefVectorType dataRef(const Usage &usage = Usage::NotFinished){
        if( resetType_ == Reset::Automatic
            || (resetType_ == Reset::OnFinished && usage == Usage::Finished))
            return RETURN_AND_RESET<ISliceable<Scalar>,RefVectorType>(*this,*refPtr_).returnAndReset();
        else
            return *refPtr_;
    }

    //TODO make double template?
    bool operator==(const ISliceable<Scalar> &other) const {
        return (data_ == other.data_) && (sliceInterval_ == other.getSliceInterval())
               && (resetType_ == other.getResetType());
    }

    //TODO make double template?
    bool operator!=(const ISliceable<Scalar> &other) const {
        return !(*this == other);
    }

protected:
    const Reset &getResetType() const { return resetType_; }
    const Interval &getSliceInterval() const { return sliceInterval_; }

    VectorType data_;
    Reset resetType_;
    Interval sliceInterval_;
    std::unique_ptr<RefVectorType> refPtr_;
};




#endif //AMOLQCPP_ISLICEABLE_H
