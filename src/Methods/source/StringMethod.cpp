//
// Created by heuer on 21.04.17.
//

//#include <solver/timeintegrationsolver.h>
#include "StringMethod.h"
#include "StringOptimizationProblem.h"
#include "solver/bfgsnssolver.h"
#include "solver/bfgssolver.h"
#include "solver/timeintegrationsolver.h"
#include "PointInterpolationGenerator.h"
#include "PenalizedLeastSquaresFitWithFixedEndsGenerator.h"
#include "PenalizedLeastSquaresFitWithLooseEndsGenerator.h"


StringMethod::StringMethod(ChainOfStates initialChain)
        :
        wf_(ElectronicWaveFunction::getInstance()),
        chain_(initialChain)
{
  StringOptimizationProblem problem(chain_.statesNumber(), chain_.coordinatesNumber(), wf_, unitTangents_);
  chain_.setValues(problem.stateValues(chain_.coordinatesAsVector()));
  reparametrizeString();
}

void StringMethod::optimizeString() {
    reparametrizeString();
    discretizeStringToChain();
    calculateUnitTangents();

  unsigned maxIterations = 100;
  unsigned iterations = 0;
    do {
      std::cout << "it " << iterations << std::endl;
      performStep();
      ++iterations;

    } while (status_ == cppoptlib::Status::IterationLimit && iterations < maxIterations);
}

void StringMethod::performStep() {
    minimizeOrthogonalToString();
    reparametrizeString();
    discretizeStringToChain();
    calculateUnitTangents();
}

void StringMethod::minimizeOrthogonalToString() {
    StringOptimizationProblem problem(chain_.statesNumber(), chain_.coordinatesNumber(), wf_, unitTangents_);
    cppoptlib::TimeIntegrationSolver<StringOptimizationProblem> solver;
    //cppoptlib::BfgsnsSolver<StringOptimizationProblem> solver;
  auto crit = cppoptlib::Criteria<double>::nonsmoothDefaults();
    crit.gradNorm = 1e-4;
    crit.iterations = 30;
    //crit.xDelta = 0.00000010;
    solver.setStopCriteria(crit);

    Eigen::VectorXd vec = chain_.coordinatesAsVector();
    auto oldvec = vec;

    solver.minimize(problem, vec);
    status_ = solver.status();
    chain_.storeCoordinateVectorInChain(chain_.coordinatesNumber(), chain_.statesNumber(), vec);
    // maybe another value call is necessary
    chain_.setValues(problem.stateValues(vec)); //TODO redesign?

    //std::cout << chain_.coordinates() << std::endl;
    //std::cout << chain_.values().transpose() << std::endl;
    std::cout << "--Solver status: " << status_ << std::endl;
}

void StringMethod::reparametrizeString() {

    //TODO CHANGE BSPLINE IMPLEMENTATION SO THAT ControlPoints are stored in cols instead of rows

    //arrange data for bspline generation
    Eigen::MatrixXd data(1+chain_.coordinatesNumber(), chain_.statesNumber());
    data.row(0) = chain_.values();
    data.block(1,0,chain_.coordinatesNumber(),chain_.statesNumber()) = chain_.coordinates();

    //TODO also fit energies, employ energy weighting
    BSplines::PointInterpolationGenerator generator(data.transpose(),3,true);
    //BSplines::PenalizedLeastSquaresFitWithFixedEndsGenerator generator(data.transpose(),//Transpose to account for different data layout
    //                                                                   unsigned(chain_.statesNumber()-1),
    //                                                                   4,true,0.0);
    Eigen::VectorXi excludedDimensions(1);
    excludedDimensions << 0;

    BSplines::BSpline bs = generator.generateBSpline(1);

    arcLengthParametrizedBSpline_ = BSplines::ArcLengthParametrizedBSpline(bs,excludedDimensions);

    distributeStates();
    calculateUnitTangents();
}

void StringMethod::distributeStates() {
    uValues_.resize(chain_.statesNumber()); // THIS determines the chain of state length

    uValues_.head(1)(0) = 0;
    uValues_.tail(1)(0) = 1;

    for (int i = 1; i < chain_.statesNumber()-1 ; ++i) {
        uValues_(i) = double(i) / double(chain_.statesNumber() - 1);
    }
}

void StringMethod::discretizeStringToChain() {

    Eigen::VectorXd values(uValues_.size());
    Eigen::MatrixXd coordinates(chain_.coordinatesNumber(),uValues_.size());

    for (int i = 0; i < uValues_.size(); ++i) {

        Eigen::VectorXd result = arcLengthParametrizedBSpline_.evaluate(uValues_(i));

        values(i) = result(0);
        coordinates.col(i) = result.tail(chain_.coordinatesNumber());
    }

    chain_ = ChainOfStates(coordinates,values);
}

void StringMethod::calculateUnitTangents() {
    unitTangents_.resize(chain_.statesNumber(),chain_.coordinatesNumber());

    for (int i = 0; i < chain_.statesNumber() ; ++i) {
        unitTangents_.row(i) = arcLengthParametrizedBSpline_.evaluate(uValues_(i),1)
                .segment(1,chain_.coordinatesNumber()).normalized(); // exclude value dimension for tangent calculation
    }
}