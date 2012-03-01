/*
	Model for Factorization Machines

	Based on the publication(s):
	Steffen Rendle (2010): Factorization Machines, in Proceedings of the 10th IEEE International Conference on Data Mining (ICDM 2010), Sydney, Australia.

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2010-12-10

	Copyright 2010 Steffen Rendle, see license.txt for more information
*/

#ifndef FM_MODEL_H_
#define FM_MODEL_H_

#include "../util/matrix.h"
#include "fm_data.h"


class fm_model {
	private:
		DVector<double> m_sum, m_sum_sqr;
	public:
		double w0;
		DVector<double> w;
		DMatrixDouble v;
	public:
		// the following values should be set:
		int num_attribute;
		
		bool k0, k1;
		int num_factor;
		
		double reg0;
		DVector<double> regw, regv;
		
		double init_stdev;
		double init_mean;
		
		fm_model();
		void debug();
		void init();
		double predict(fv_vector& x);
		double predict(fv_vector &x, DVector<double> &sum, DVector<double> &sum_sqr);
		double predict_factor( fv_vector &x, int factor);
		double predict_factor( fv_vector &x, double &sum, double &sum_sqr, int factor);
	
	
};



fm_model::fm_model() {
	num_factor = 0;
	init_mean = 0;
	init_stdev = 0.01;
	reg0 = 0;
	k0 = true;
	k1 = true;
}

void fm_model::debug() {
	std::cout << "num_attributes=" << num_attribute << std::endl;
	std::cout << "k0=" << k0 << std::endl;
	std::cout << "k1=" << k1 << std::endl;
	std::cout << "k2=" << num_factor << std::endl;
	std::cout << "r0=" << reg0 << std::endl;
	if (regw.dim > 0) {
		std::cout << "r1[0]=" << regw(0) << std::endl;
	}
	if (regv.dim > 0) {
		std::cout << "r2[0]=" << regv(0) << std::endl;
	}
	std::cout << "init ~ N(" << init_mean << "," << init_stdev << ")" << std::endl;
}

void fm_model::init() {
	w0 = 0;
	w.setSize(num_attribute);
	v.setSize(num_attribute, num_factor);
	w.init(0);
	v.init(init_mean, init_stdev);
	m_sum.setSize(num_factor);
	m_sum_sqr.setSize(num_factor);
	regw.setSize(num_attribute);
	regv.setSize(num_attribute);
	regw.init(0);
	regv.init(0);
}

double fm_model::predict(fv_vector& x) {
	return predict(x, m_sum, m_sum_sqr);		
}

double fm_model::predict(fv_vector &x, DVector<double> &sum, DVector<double> &sum_sqr) {
	double result = 0;
	if (k0) {	
		result += w0;
	}
	if (k1) {
		for (int i = 0; i < x.size; i++) {
			assert(x.data[i].feature_id < num_attribute);
			result += w(x.data[i].feature_id) * x.data[i].value;
		}
	}
	for	(int f = 0; f < num_factor; f++) {
		sum(f) = 0;
		sum_sqr(f) = 0;
		for (int i = 0; i < x.size; i++) {
			double d = v(x.data[i].feature_id,f) * x.data[i].value;
			sum(f) += d;
			sum_sqr(f) += d*d;
		}
		result += 0.5 * (sum(f)*sum(f) - sum_sqr(f));
	}
	return result;
}

double fm_model::predict_factor( fv_vector &x, int factor) {
	double sum, sum_sqr;
	return predict_factor( x, sum, sum_sqr, factor );
}

double fm_model::predict_factor( fv_vector &x, double &sum, double &sum_sqr, int factor) {
	sum = 0;
	sum_sqr = 0;
	for (int i = 0; i < x.size; i++) {
		double d = v(x.data[i].feature_id,factor) * x.data[i].value;
		sum += d;
		sum_sqr += d*d;
	}
	return 0.5 * (sum*sum - sum_sqr);
}


#endif /*FM_MODEL_H_*/
