/*
	Sparse data structure 

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2010-12-10

	Copyright 2010 Steffen Rendle, see license.txt for more information
*/

#ifndef FM_DATA_H_
#define FM_DATA_H_

struct fv_pair {
    int feature_id;
    double value;
};
	
struct fv_vector {
	fv_pair* data;
	int size;
};

#endif /*FM_DATA_H_*/
