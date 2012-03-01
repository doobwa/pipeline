/*
	Generic learning method for factorization machines

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2010-12-10

	Copyright 2010 Steffen Rendle, see license.txt for more information
*/

#ifndef FM_LEARN_H_
#define FM_LEARN_H_

#include <cmath>
#include "Data.h"
#include "../../fm_core/fm_model.h"
#include "../../util/rlog.h"
#include "../../util/util.h"


class fm_learn {
	public:
		fm_model* fm;
		double min_target;
		double max_target;

		int task; // 0=regression, 1=classification		

		RLog* log;

		fm_learn() { log = NULL; task = 0; } 
		
		
		virtual void init() {
			if (log != NULL) {
				if (task == 0) {
					log->addField("rmse", std::numeric_limits<double>::quiet_NaN());
					log->addField("mae", std::numeric_limits<double>::quiet_NaN());
				} else if (task == 1) {
					log->addField("accuracy", std::numeric_limits<double>::quiet_NaN());
				} else {
					throw "unknown task";
				}
				log->addField("time_pred", std::numeric_limits<double>::quiet_NaN());
				log->addField("time_learn", std::numeric_limits<double>::quiet_NaN());
			}
		}

		double evaluate(Data& data) {
			if (task == 0) {
				return evaluate_regression(data);
			} else if (task == 1) {
				return evaluate_classification(data);
			} else {
				throw "unknown task";
			}
		}
		double evaluate_classification(Data& data) {
			int num_correct = 0;
			double eval_time = getusertime();
			for (uint j = 0; j < data.data.dim; j++) {
				double p = fm->predict(data.data(j));
				if (((p >= 0) && (data.target(j) >= 0)) || ((p < 0) && (data.target(j) < 0))) {
					num_correct++;
				}	
			}	
			eval_time = (getusertime() - eval_time);
			// log the values
			if (log != NULL) {
				log->log("accuracy", (double) num_correct / (double)data.data.dim);
				log->log("time_pred", eval_time);
			}

			return (double) num_correct / (double) data.data.dim;
		}
		double evaluate_regression(Data& data) {
			double rmse_sum_sqr = 0;
			double mae_sum_abs = 0;
			double eval_time = getusertime();
			for (uint j = 0; j < data.data.dim; j++) {
				double p = fm->predict(data.data(j));
				p = std::min(max_target, p);
				p = std::max(min_target, p);
				double err = p - data.target(j);
				rmse_sum_sqr += err*err;
				mae_sum_abs += std::abs((double)err);	
			}	
			eval_time = (getusertime() - eval_time);
			// log the values
			if (log != NULL) {
				log->log("rmse", std::sqrt(rmse_sum_sqr/data.data.dim));
				log->log("mae", mae_sum_abs/data.data.dim);
				log->log("time_pred", eval_time);
			}

			return std::sqrt(rmse_sum_sqr/data.data.dim);
		}
		
		virtual void learn(Data& train, Data& test) { }
		
		virtual void predict(Data& data, DVector<double>& out) {
			assert(data.data.dim == out.dim);
			for (uint j = 0; j < data.data.dim; j++) {
				double p = fm->predict(data.data(j));
				p = std::min(max_target, p);
				p = std::max(min_target, p);
				out(j) = p;
			}				
		} 
		
		virtual void debug() { 
			std::cout << "task=" << task << std::endl;
			std::cout << "min_target=" << min_target << std::endl;
			std::cout << "max_target=" << max_target << std::endl;		
		}
};

#endif /*FM_LEARN_H_*/
