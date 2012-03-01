/*
	Generic SGD for elementwise and pairwise losses for Factorization Machines

	Based on the publication(s):
	Steffen Rendle (2010): Factorization Machines, in Proceedings of the 10th IEEE International Conference on Data Mining (ICDM 2010), Sydney, Australia.

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2010-12-10

	Copyright 2010 Steffen Rendle, see license.txt for more information
*/

#ifndef FM_SGD_H_
#define FM_SGD_H_

#include "fm_model.h"

void fm_SGD(fm_model* fm, const double& learn_rate, fv_vector &x, const double multiplier, DVector<double> &sum) {
	if (fm->k0) {
		double& w0 = fm->w0;
		w0 -= learn_rate * (multiplier + fm->reg0 * w0);
	}
	if (fm->k1) {
		for (int i = 0; i < x.size; i++) {
			double& w = fm->w(x.data[i].feature_id);
			w -= learn_rate * (multiplier * x.data[i].value + fm->regw(x.data[i].feature_id) * w);
		}
	}	
	for (int f = 0; f < fm->num_factor; f++) {
		for (int i = 0; i < x.size; i++) {
			double& v = fm->v(x.data[i].feature_id, f);
			double grad = sum(f) * x.data[i].value - v * x.data[i].value * x.data[i].value; 
			v -= learn_rate * (multiplier * grad + fm->regv(x.data[i].feature_id) * v);
		}
	}	
}
		
void fm_pairSGD(fm_model* fm, const double& learn_rate, fv_vector &x_pos, fv_vector &x_neg, const double multiplier, DVector<double> &sum_pos, DVector<double> &sum_neg, DVector<bool> &grad_visited, DVector<double> &grad) {
	if (fm->k0) {
		double& w0 = fm->w0;
		w0 -= fm->reg0 * w0; // w0 should always be 0			
	}
	if (fm->k1) {
		for (int i = 0; i < x_pos.size; i++) {
			grad(x_pos.data[i].feature_id) = 0;
			grad_visited(x_pos.data[i].feature_id) = false;
		}
		for (int i = 0; i < x_neg.size; i++) {
			grad(x_neg.data[i].feature_id) = 0;
			grad_visited(x_neg.data[i].feature_id) = false;
		}
		for (int i = 0; i < x_pos.size; i++) {
			grad(x_pos.data[i].feature_id) += x_pos.data[i].value;
		}
		for (int i = 0; i < x_neg.size; i++) {
			grad(x_neg.data[i].feature_id) -= x_neg.data[i].value;
		}
		for (int i = 0; i < x_pos.size; i++) {
			int& attr_id = x_pos.data[i].feature_id;
			if (! grad_visited(attr_id)) {
				double& w = fm->w(attr_id);
				w -= learn_rate * (multiplier * grad(attr_id) + fm->regw(attr_id) * w);
				grad_visited(attr_id) = true;
			}
		}
		for (int i = 0; i < x_neg.size; i++) {
			int& attr_id = x_neg.data[i].feature_id;
			if (! grad_visited(attr_id)) {
				double& w = fm->w(attr_id);
				w -= learn_rate * (multiplier * grad(attr_id) + fm->regw(attr_id) * w);
				grad_visited(attr_id) = true;
			}
		}			
	}
	
	for (int f = 0; f < fm->num_factor; f++) {
		for (int i = 0; i < x_pos.size; i++) {
			grad(x_pos.data[i].feature_id) = 0;
			grad_visited(x_pos.data[i].feature_id) = false;
		}
		for (int i = 0; i < x_neg.size; i++) {
			grad(x_neg.data[i].feature_id) = 0;
			grad_visited(x_neg.data[i].feature_id) = false;
		}
		for (int i = 0; i < x_pos.size; i++) {
			grad(x_pos.data[i].feature_id) += sum_pos(f) * x_pos.data[i].value - fm->v(x_pos.data[i].feature_id, f) * x_pos.data[i].value * x_pos.data[i].value; 
		}
		for (int i = 0; i < x_neg.size; i++) {
			grad(x_neg.data[i].feature_id) -= sum_neg(f) * x_neg.data[i].value - fm->v(x_neg.data[i].feature_id, f) * x_neg.data[i].value * x_neg.data[i].value;
		}
		for (int i = 0; i < x_pos.size; i++) {
			int& attr_id = x_pos.data[i].feature_id;
			if (! grad_visited(attr_id)) {
				double& v = fm->v(attr_id, f);
				v -= learn_rate * (multiplier * grad(attr_id) + fm->regv(attr_id) * v);
				grad_visited(attr_id) = true;
			}
		}
		for (int i = 0; i < x_neg.size; i++) {
			int& attr_id = x_neg.data[i].feature_id;
			if (! grad_visited(attr_id)) {
				double& v = fm->v(attr_id, f);
				v -= learn_rate * (multiplier * grad(attr_id) + fm->regv(attr_id) * v);
				grad_visited(attr_id) = true;
			}
		}	
	

	}
			
} 
#endif /*FM_SGD_H_*/
