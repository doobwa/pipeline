/*
	Stochastic Gradient Descent based learning for classification and regression

	Based on the publication(s):
	Steffen Rendle (2010): Factorization Machines, in Proceedings of the 10th IEEE International Conference on Data Mining (ICDM 2010), Sydney, Australia.

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2010-12-10

	Copyright 2010 Steffen Rendle, see license.txt for more information
*/


#ifndef FM_LEARN_SGD_ELEMENT_H_
#define FM_LEARN_SGD_ELEMENT_H_

#include "fm_learn_sgd.h"

class fm_learn_sgd_element: public fm_learn_sgd {
	public:
		virtual void init() {
			fm_learn_sgd::init();
		}
		virtual void learn(Data& train, Data& test) {
			fm_learn_sgd::learn(train, test);

			// traverse training data randomly			
			DVector<int> shuffle;
			shuffle.setSize(train.data.dim);
			for (uint j = 0; j < train.data.dim; j++) {
				shuffle(j) = j;
			}
			for (uint j = 0; j < train.data.dim*10; j++) {
				int idx1 = rand() % train.data.dim;
				int idx2 = rand() % train.data.dim;
				int temp = shuffle(idx1);
				shuffle(idx1) = shuffle(idx2);
				shuffle(idx2) = temp;				
			}

			// SGD
			for (int i = 0; i < num_iter; i++) {
			
				double iteration_time = getusertime();
				for (uint j = 0; j < train.data.dim; j++) {
					int row_id = shuffle(j);
					double p = fm->predict(train.data(row_id), sum, sum_sqr);
					double mult = 0;
					if (task == 0) {
						p = std::min(max_target, p);
						p = std::max(min_target, p);
						mult = -(train.target(row_id)-p);
					} else if (task == 1) {
						/*if (1 <= p*train.target(row_id)) {						
							mult = 0;
						} else {
							mult = -train.target(row_id);
						}*/
						mult = -train.target(row_id)*(1.0-1.0/(1.0+exp(-train.target(row_id)*p)));
					}				
					SGD(train.data(row_id), mult, sum);					
				}				
				iteration_time = (getusertime() - iteration_time);
				if (log != NULL) {
					log->log("time_learn", iteration_time);
				}	
				double rmse_train = evaluate(train);
				double rmse_test = evaluate(test);
				std::cout << "#Iter=" << std::setw(3) << i << "\tTrain=" << rmse_train << "\tTest=" << rmse_test << std::endl;
				if (log != NULL) {
					log->newLine();
				}
			}		
		}
		
};

#endif /*FM_LEARN_SGD_ELEMENT_H_*/
