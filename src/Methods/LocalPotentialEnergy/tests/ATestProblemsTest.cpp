//
// Created by Leonard Reuter on 12.03.18.
//

#include <gtest/gtest.h>
#include <Eigen/Core>
#include "solver/gradientdescentsolver.h"
#include "solver/gradientdescentsimplesolver.h"
#include "solver/bfgssolver.h"
#include "TestProblems.h"

using namespace testing;
using namespace Eigen;
using namespace TestProblems;

class ATestProblemsTest : public Test {};

TEST_F(ATestProblemsTest, testProblemValue) {
    TestProblem problem;

    Eigen::VectorXd z(2);
    z << -2,3;

    ASSERT_DOUBLE_EQ(problem.value(z),1);
}

TEST_F(ATestProblemsTest, testConstraintValue) {
    TestConstraint constraint;

    Eigen::VectorXd z(2);
    z << -2,3;

    ASSERT_DOUBLE_EQ(constraint.value(z),13);
}

TEST_F(ATestProblemsTest, testProblemGradient) {
    TestProblem problem;

    Eigen::VectorXd z(2);
    z << -2,3;

    Eigen::VectorXd grad = z;

    problem.gradient(z,grad);

    Eigen::VectorXd reference(2);
    reference << 1,1;
    ASSERT_EQ(grad,reference);
}

TEST_F(ATestProblemsTest, testConstraintGradient) {
    TestConstraint constraint;

    Eigen::VectorXd z(2);
    z << -2,3;

    Eigen::VectorXd grad = z;

    constraint.gradient(z,grad);

    Eigen::VectorXd reference(2);
    reference << -4,6;

    ASSERT_DOUBLE_EQ(grad[0],reference[0]);
    ASSERT_DOUBLE_EQ(grad[1],reference[1]);
}

TEST_F(ATestProblemsTest, testProblemHessian) {
    TestProblem problem;

    Eigen::VectorXd z(2);
    z << -2,3;

    Eigen::MatrixXd hessian(2,2);

    problem.hessian(z,hessian);

    Eigen::MatrixXd reference(2,2);
    reference(0,0) = 0;
    reference(0,1) = 0;
    reference(1,0) = 0;
    reference(1,1) = 0;

    ASSERT_EQ(hessian,reference);
}

TEST_F(ATestProblemsTest, testConstraintHessian) {
    TestConstraint constraint;

    Eigen::VectorXd z(2);
    z << -2,3;

    Eigen::MatrixXd hessian(2,2);

    constraint.hessian(z,hessian);

    Eigen::MatrixXd reference(2,2);
    reference(0,0) = 2;
    reference(0,1) = 0;
    reference(1,0) = 0;
    reference(1,1) = 2;

    ASSERT_EQ(hessian,reference);
}

TEST_F(ATestProblemsTest, GradientDescent) {
    TestConstraint constraint;

    Eigen::VectorXd z(2);
    z << -2,3;

    cppoptlib::Criteria<double> crit = cppoptlib::Criteria<double>::defaults();

    cppoptlib::GradientDescentSolver<TestConstraint> solver;
    solver.setDebug(cppoptlib::DebugLevel::None);
    solver.setStopCriteria(crit);

    solver.minimize(constraint, z);

    Eigen::VectorXd ref(2);
    ref << 0,0;

    ASSERT_GT(1e-4,(z-ref).norm());
}

TEST_F(ATestProblemsTest, GradientDescentSimple) {
    TestConstraint constraint;

    Eigen::VectorXd z(2);
    z << -2,3;

    cppoptlib::Criteria<double> crit = cppoptlib::Criteria<double>::defaults();
    crit.gradNorm = 1e-3;

    cppoptlib::GradientDescentSimpleSolver<TestConstraint> solver;
    solver.setDebug(cppoptlib::DebugLevel::None);
    solver.setStopCriteria(crit);

    solver.minimize(constraint, z);

    Eigen::VectorXd ref(2);
    ref << 0,0;

    ASSERT_GT(1e-3,(z-ref).norm());
}

TEST_F(ATestProblemsTest, Bfgs) {
    TestConstraint constraint;

    Eigen::VectorXd z(2);
    z << -2,3;

    cppoptlib::Criteria<double> crit = cppoptlib::Criteria<double>::defaults();

    cppoptlib::BfgsSolver<TestConstraint> solver;
    solver.setDebug(cppoptlib::DebugLevel::None);
    solver.setStopCriteria(crit);

    solver.minimize(constraint, z);

    Eigen::VectorXd ref(2);
    ref << 0,0;

    ASSERT_GT(1e-4,(z-ref).norm());
}