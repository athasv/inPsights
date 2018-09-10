#ifndef VANTAGEPOINTTREE_H
#define VANTAGEPOINTTREE_H

#include "Dataset.h"
#include <vector>
#include <queue>
#include <limits>
#include <spdlog/spdlog.h>

namespace Clustering {

    template<typename Scalar, double ( *distance )(
            const Eigen::Matrix<Scalar,Eigen::Dynamic,1> &,
            const Eigen::Matrix<Scalar,Eigen::Dynamic,1> &)>
    class VantagePointTree {
        using VectorType = Eigen::Matrix<Scalar,Eigen::Dynamic,1>;

    public:
        VantagePointTree(const VantagePointTree&) = delete;
        VantagePointTree& operator=(const VantagePointTree&) = delete;

    private:

        struct HeapItem {
            HeapItem(size_t idx, double dist)
                    : idx(idx), dist(dist) {
            }

            size_t idx;
            double dist;

            bool operator<(const HeapItem &o) const {
                return dist < o.dist;
            }
        };

    public:
        static const uint32_t FIRTS_NODE_IDX = 1;

        VantagePointTree()
                : VantagePointTree(1e-7) {
        }

        explicit VantagePointTree(double similarityDistance)
                : rootIndex_(FIRTS_NODE_IDX),nextIndex_(FIRTS_NODE_IDX), similarityDistance(similarityDistance) {
        }

        ~VantagePointTree() = default;

        void create(const std::shared_ptr<Dataset<Scalar>> dataset) {
            rootIndex_ = FIRTS_NODE_IDX;
            nextIndex_ = FIRTS_NODE_IDX;
            dataset_ = dataset;

            const auto &d = dataset_->data();

            nodelist_.resize(d.size() + 1);
            itemsIndex_.resize(d.size());

            for (size_t i = 0; i < d.size(); ++i) {
                itemsIndex_[i] = i;
            }

            rootIndex_ = buildFromPoints(0, d.size(), d);
        }

        void searchByDistance(const VectorType &target, double t, std::vector<std::pair<size_t, float>> &nlist) const {
            nlist.clear();

            const auto &d = dataset_->data();

            searchByDistance(rootIndex_, target, nlist, t, d);
        }

        void searchByK(const VectorType &target, size_t k, std::vector<std::pair<size_t, float>> &nlist,
                       bool excludeExactQ = false) const {
            nlist.clear();

            double t = std::numeric_limits<double>::max();

            const auto &d = dataset_->data();

            std::priority_queue<HeapItem> heap;

            searchByK(rootIndex_, target, nlist, k, d, heap, t, excludeExactQ);

            while (!heap.empty()) {
                const auto &top = heap.top();
                nlist.push_back(std::make_pair(top.idx, top.dist));
                heap.pop();
            }
        }

    private:
        struct Node {
            uint32_t index;
            double threshold;
            uint32_t left;
            uint32_t right;

            Node() : index(0),
                     threshold(0.),
                     left(0),
                     right(0) {}
        };

        uint32_t rootIndex_;
        uint32_t nextIndex_;
        double similarityDistance;
        typedef std::vector<Node> TNodeList;

        TNodeList nodelist_;

        std::shared_ptr<Dataset<Scalar>> dataset_;
        std::vector<size_t> itemsIndex_;

        struct DistanceComparator {
            size_t itemIndex;
            const std::vector<VectorType> &items;

            DistanceComparator(size_t i, const std::vector<VectorType> &d)
                    : itemIndex(i), items(d) {
            }

            bool operator()(size_t a, size_t b) {
                return distance(items[itemIndex], items[a]) < distance(items[itemIndex], items[b]);
            }
        };

        uint32_t buildFromPoints(uint32_t lower, uint32_t upper, const std::vector<VectorType> &d) {
            if (upper == lower) {
                return 0;
            }

            uint32_t currentNodeIndex = nextIndex_++;

            Node &node = nodelist_[currentNodeIndex];
            node.index = lower;

            if (upper - lower > 1) {

                int i = (int) ((double) rand() / RAND_MAX * (upper - lower - 1)) + lower;
                std::swap(itemsIndex_[lower], itemsIndex_[i]);

                int median = (upper + lower) / 2;

                std::nth_element(
                        itemsIndex_.begin() + lower + 1,
                        itemsIndex_.begin() + median,
                        itemsIndex_.begin() + upper,
                        DistanceComparator(itemsIndex_[lower], d));
                node.threshold = distance(d[itemsIndex_[lower]], d[itemsIndex_[median]]);

                node.index = lower;
                node.left = buildFromPoints(lower + 1, median, d);
                node.right = buildFromPoints(median, upper, d);
            }

            return currentNodeIndex;
        }

        void searchByK(uint32_t nodeIndex,
                       const VectorType &target,
                       std::vector<std::pair<size_t, float>> &neighborList,
                       size_t k,
                       const std::vector<VectorType> &d,
                       std::priority_queue<HeapItem> &heap,
                       double &t,
                       bool excludeExactQ) const {
            if (nodeIndex == 0)
                return;

            const Node &node = nodelist_[nodeIndex];

            const double dist = distance(d[itemsIndex_[node.index]], target);

            if (dist < t) {

                if (excludeExactQ && dist < similarityDistance) {
                    /** do nothing on similar points **/
                } else {

                    if (heap.size() == k)
                        heap.pop();
                    heap.push(HeapItem(itemsIndex_[node.index], dist));
                    if (heap.size() == k)
                        t = heap.top().dist;
                }
            }
            spdlog::get("console")->info("dist = {0}, tau = {1}, dist<t == {2}, heapsize = {3}",dist,t,(dist < t), heap.size());

            if (node.left == 0 && node.right == 0) {
                return;
            }

            if (dist < node.threshold) {
                if (dist - t <= node.threshold) {
                    searchByK(node.left, target, neighborList, k, d, heap, t, excludeExactQ);
                }

                if (dist + t >= node.threshold) {
                    searchByK(node.right, target, neighborList, k, d, heap, t, excludeExactQ);
                }

            } else {
                if (dist + t >= node.threshold) {
                    searchByK(node.right, target, neighborList, k, d, heap, t, excludeExactQ);
                }

                if (dist - t <= node.threshold) {
                    searchByK(node.left, target, neighborList, k, d, heap, t, excludeExactQ);
                }
            }
        }

        void searchByDistance(uint32_t nodeIndex,
                              const VectorType &target,
                              std::vector<std::pair<size_t, float>> &neighborList,
                              double t,
                              const std::vector<VectorType> &d) const {
            if (nodeIndex == 0)
                return;

            const Node &node = nodelist_[nodeIndex];

            // node zero treshold hack
            // double dist = 0.0;
            // if ( node.threshold > 0.0 ) {
            //     dist = distance( d[m_items_idx[node.index]], target );
            // }

            const double dist = distance(d[itemsIndex_[node.index]], target);

            if (dist < t) {
                neighborList.push_back(std::make_pair(itemsIndex_[node.index], dist));
            }

            if (node.left == 0 && node.right == 0) {
                return;
            }

            if (dist < node.threshold) {
                if (dist - t <= node.threshold) {
                    spdlog::get("console")->info("{0} {1} {2} LEFT", t,dist,node.threshold);
                    searchByDistance(node.left, target, neighborList, t, d);
                }

                if (dist + t >= node.threshold) {
                    spdlog::get("console")->info("{0} {1} {2} RIGHT", t,dist,node.threshold);
                    searchByDistance(node.right, target, neighborList, t, d);
                }

            } else {
                if (dist + t >= node.threshold) {
                    spdlog::get("console")->info("{0} {1} {2} RIGHT", t,dist,node.threshold);
                    searchByDistance(node.right, target, neighborList, t, d);
                }

                if (dist - t <= node.threshold) {
                    spdlog::get("console")->info("{0} {1} {2} LEFT", t,dist,node.threshold);
                    searchByDistance(node.left, target, neighborList, t, d);
                }
            }
        }
    };
}

#endif // VANTAGEPOINTTREE_H
