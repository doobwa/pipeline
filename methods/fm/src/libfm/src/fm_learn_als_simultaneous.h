/*
	libFM: Optimization using alternating least squares

	Notes:
	In each iteration every single parameter is optimized, starting from the global bias, the one-way interactions and finally each factor layer of the two-way interactions.

	Based on the publication(s):
	Steffen Rendle, Zeno Gantner, Christoph Freudenthaler, Lars Schmidt-Thieme (2011): Fast Context-aware Recommendations with Factorization Machines, in Proceedings of the 34th international ACM SIGIR conference on Research and development in information retrieval (SIGIR 2011), Beijing, China.

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2011-07-14

	Copyright 2010-2011 Steffen Rendle, see license.txt for more information
*/

#ifndef FM_LEARN_ALS_SIMULTANEOUS_H_
#define FM_LEARN_ALS_SIMULTANEOUS_H_

#include <cmath>
#include "Data.h"
#include "fm_learn_als.h"

class fm_learn_als_simultaneous : public fm_learn_als {
	protected:
		virtual void _learn(Data& train, Data& test, DVector<fv_vector>& data_t) {
			for (int i = 0; i < num_iter; i++) {
				double iteration_time = getusertime();
				if (fm->k0) {
					optimize_w0(fm->w0, fm->reg0, train);
				}
				for (int j = 0; j < train.num_feature; j++) {
					if (fm->k1) {
						optimize_w(fm->w(j), fm->regw(j), data_t(j));
					}
				}

				for (int f = 0; f < fm->num_factor; f++) {
					for (int j = 0; j < train.num_feature; j++) {	
						optimize_v(train.data, data_t(j), j, f);
					}
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

#endif /*FM_LEARN_ALS_SIMULTANEOUS_H_*/
