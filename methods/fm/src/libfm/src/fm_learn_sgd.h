/*
	Stochastic Gradient Descent based learning

	Based on the publication(s):
	Steffen Rendle (2010): Factorization Machines, in Proceedings of the 10th IEEE International Conference on Data Mining (ICDM 2010), Sydney, Australia.

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2010-12-10

	Copyright 2010 Steffen Rendle, see license.txt for more information
*/

#ifndef FM_LEARN_SGD_H_
#define FM_LEARN_SGD_H_

#include "fm_learn.h"
#include "../../fm_core/fm_sgd.h"

class fm_learn_sgd: public fm_learn {
	protected:
		DVector<double> sum, sum_sqr;
	public:
		int num_iter;
		double learn_rate;
		
		virtual void init() {		
			fm_learn::init();	
			sum.setSize(fm->num_factor);		
			sum_sqr.setSize(fm->num_factor);
		}		

		virtual void learn(Data& train, Data& test) { 
			fm_learn::learn(train, test);
			std::cout << "learnrate=" << learn_rate << std::endl;
			std::cout << "#iterations=" << num_iter << std::endl;
		}

		void SGD(fv_vector &x, const double multiplier, DVector<double> &sum) {
			fm_SGD(fm, learn_rate, x, multiplier, sum); 
		}
		
		void debug() {
			std::cout << "num_iter=" << num_iter << std::endl;
			fm_learn::debug();			
		}
};

#endif /*FM_LEARN_SGD_H_*/
