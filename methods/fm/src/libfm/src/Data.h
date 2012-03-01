/*
	Data container for Factorization Machines 

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2010-12-10

	Copyright 2010 Steffen Rendle, see license.txt for more information
*/

#ifndef DATA_H_
#define DATA_H_

#include <limits>
#include "../../util/matrix.h"
#include "../../util/token_reader.h"
#include "../../fm_core/fm_data.h"
#include "../../fm_core/fm_model.h"


class Data {
	public:
		DVector<fv_vector> data;
		DVector<double> target;
		int num_feature;
		double min_target;
		double max_target;
		
		void load(std::string filename);	
		void debug();
};

void Data::load(std::string filename) {
	int num_rows = 0;
	int num_values = 0;
	num_feature = 0;
	min_target = +std::numeric_limits<double>::max();
	max_target = -std::numeric_limits<double>::max();
	
	// (1) determine the number of rows and the maximum feature_id
	{
		std::ifstream fData(filename.c_str());
		if (! fData.is_open()) {
			throw "unable to open " + filename;
		}
		token_reader fData2(&fData);
		do {
			double _target = fData2.readFloat();
			if (! fData2.is_missing) {
				min_target = std::min(_target, min_target);
				max_target = std::max(_target, max_target);			
				num_rows++;
				while ((fData2.ch != 0) && (! fData2.isNewLine(fData2.ch))) {
					int _feature = fData2.readInt();
					num_feature = std::max(_feature, num_feature);
					/*double _value = */fData2.readFloat();
					num_values++;	
				}
			}
		} while (fData2.ch != 0);	
		fData.close();
	}	
	num_feature++; // number of feature is bigger (by one) than the largest value
	
	std::cout << "num_rows=" << num_rows << "\tnum_values=" << num_values << "\tnum_features=" << num_feature << "\tmin_target=" << min_target << "\tmax_target=" << max_target << std::endl;
	data.setSize(num_rows);
	target.setSize(num_rows);
	
	fv_pair* cache = new fv_pair[num_values];
	
	// (2) read the data
	{
		std::ifstream fData(filename.c_str());
		if (! fData.is_open()) {
			throw "unable to open " + filename;
		}
		int row_id = 0;
		int cache_id = 0;
		token_reader fData2(&fData);
		do {
			double _target = fData2.readFloat();
			if (! fData2.is_missing) {
				assert(row_id < num_rows);
				target.value[row_id] = _target;
				data.value[row_id].data = &(cache[cache_id]);
				data.value[row_id].size = 0;
			
				while ((fData2.ch != 0) && (! fData2.isNewLine(fData2.ch))) {
					assert(cache_id < num_values);
					cache[cache_id].feature_id = fData2.readInt();
					cache[cache_id].value = fData2.readFloat();
					cache_id++;
					data.value[row_id].size++;
				}
				row_id++;
			}
		} while (fData2.ch != 0);	
		fData.close();
		
		assert(num_rows == row_id);
		assert(num_values == cache_id);		
	}	
}

void Data::debug() {
	for (uint i = 0; i < std::min(data.dim, (uint)4); i++) {
		std::cout << target(i);
		for (int j = 0; j < data(i).size; j++) {
			std::cout << " " << data(i).data[j].feature_id << ":" << data(i).data[j].value;	
		}
		std::cout << std::endl;
	}	
}

#endif /*DATA_H_*/
