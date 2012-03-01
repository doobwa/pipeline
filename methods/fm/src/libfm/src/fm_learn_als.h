/*
	libFM: Optimization using alternating least squares

	Based on the publication(s):
	Steffen Rendle, Zeno Gantner, Christoph Freudenthaler, Lars Schmidt-Thieme (2011): Fast Context-aware Recommendations with Factorization Machines, in Proceedings of the 34th international ACM SIGIR conference on Research and development in information retrieval (SIGIR 2011), Beijing, China.

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2011-07-14

	Copyright 2010-2011 Steffen Rendle, see license.txt for more information
*/

#ifndef FM_LEARN_ALS_H_
#define FM_LEARN_ALS_H_

#include <cmath>
#include "Data.h"

class fm_learn_als : public fm_learn {
	protected:
		// Caches
		DVector<double> error;
		DMatrix<double> q;

		// Find the optimal value for the global bias (0-way interaction)
		void optimize_w0(double& w0, double& reg, Data& train) {
			double a = 0;
			for (uint i = 0; i < train.data.dim; i++) {
				a += error(i) - w0;
			}
			// update w0
			double w0_old = w0;
			w0 = - a / (train.data.dim + reg);
			// update error
			for (uint i = 0; i < train.data.dim; i++) {
				error(i) = error(i) - w0_old + w0;
			}
	
		}

		// Find the optimal value for the 1-way interaction w
		void optimize_w(double& w, double& reg, fv_vector& feature_data) {
			double a = 0;
			double b = 0;
			for (int i_fd = 0; i_fd < feature_data.size; i_fd++) {	
				int& train_case_index = feature_data.data[i_fd].feature_id;		
				double x_li = feature_data.data[i_fd].value;	
				a += x_li * (error(train_case_index) - w * x_li);
				b += x_li * x_li;
			}
			// update w:
			double w_old = w; 
			w = - (a) / (b + reg);
			// update error:
			for (int i_fd = 0; i_fd < feature_data.size; i_fd++) {	
				int& train_case_index = feature_data.data[i_fd].feature_id;	
				double& x_li = feature_data.data[i_fd].value;	
				double h = x_li;
				error(train_case_index) = error(train_case_index) - h * (w_old - w);	
			}
		}

		// Find the optimal value for the 2-way interaction parameter v
		void optimize_v(DVector<fv_vector>& data, fv_vector& feature_data, int feature_id, int factor_id) {
			double& factor_value = fm->v(feature_id, factor_id);
			double a = 0;
			double b = 0;
			for (int i_fd = 0; i_fd < feature_data.size; i_fd++) {	
				int& train_case_index = feature_data.data[i_fd].feature_id;		
				double& x_li = feature_data.data[i_fd].value;
				double h = x_li * ( q(train_case_index, factor_id) - x_li * fm->v(feature_id, factor_id));
				a += h * (error(train_case_index) - h * fm->v(feature_id, factor_id));
				b += h * h;
			}
			// update v:
			double factor_value_old = factor_value; 
			factor_value = - (a) / (b + fm->regv(feature_id));
			
			// update error and q:
			for (int i_fd = 0; i_fd < feature_data.size; i_fd++) {	
				int& train_case_index = feature_data.data[i_fd].feature_id;		
				double& x_li = feature_data.data[i_fd].value;	

				double h_old = x_li * ( q(train_case_index, factor_id) - x_li * factor_value_old);
				q(train_case_index, factor_id) = q(train_case_index, factor_id) - x_li * factor_value_old + x_li * factor_value;
				double h_new = x_li * ( q(train_case_index, factor_id) - x_li * factor_value );
				error(train_case_index) = error(train_case_index) - factor_value_old * h_old + factor_value * h_new;
			}
		}

		
		virtual void _learn(Data& train, Data& test, DVector<fv_vector>& data_t) {};
	
	public:
		int num_iter;
		
		
		virtual void init() {
			fm_learn::init();
		}
		
		
		virtual void learn(Data& train, Data& test) {
			// init error data structure
			error.setSize(train.data.dim);
			for (uint i = 0; i < train.data.dim; i++) {
				error(i) = fm->predict(train.data(i)) - train.target(i);
			}			
			// init temporary data structure for precalculating qs:
			q.setSize(train.data.dim, fm->num_factor);
			for (uint i = 0; i < train.data.dim; i++) {
				for (int f = 0; f < fm->num_factor; f++) {
					q(i,f) = 0;
					for (int j = 0; j < train.data(i).size; j++) {
					 	q(i,f) += fm->v(train.data(i).data[j].feature_id,f) * train.data(i).data[j].value;
					}
				}
				error(i) = fm->predict(train.data(i)) - train.target(i);
			}			

			// make transpose copy of training data
			DVector<fv_vector> data_t;
			data_t.setSize(train.num_feature);
			{			
				// find dimensionality of matrix
				DVector<uint> num_values_per_column;
				num_values_per_column.setSize(train.num_feature);
				num_values_per_column.init(0);
				uint num_values = 0;
				for (uint i = 0; i < train.data.dim; i++) {
					for (int j = 0; j < train.data(i).size; j++) {
						num_values_per_column(train.data(i).data[j].feature_id)++;
						num_values++;
					}
				}	
				// create ds for values
				fv_pair* cache = new fv_pair[num_values];
				uint cache_id = 0;
				for (uint i = 0; i < data_t.dim; i++) {
					data_t.value[i].data = &(cache[cache_id]);
					data_t(i).size = num_values_per_column(i);
					cache_id += num_values_per_column(i);				
				} 
				// write the data into the transpose matrix
				num_values_per_column.init(0); // num_values per column now contains the pointer on the first empty field
				for (uint i = 0; i < train.data.dim; i++) {
					for (int j = 0; j < train.data(i).size; j++) {
						int f_id = train.data(i).data[j].feature_id;
						uint cntr = num_values_per_column(f_id);
						assert(cntr < (uint) data_t(f_id).size);
						data_t(f_id).data[cntr].feature_id = i;
						data_t(f_id).data[cntr].value = train.data(i).data[j].value;
						num_values_per_column(f_id)++;
					}
				}		
			}

			_learn(train, test, data_t);

			// free data structures
			error.setSize(0);
			q.setSize(0,0);
		}

};

#endif /*FM_LEARN_ALS_H_*/
