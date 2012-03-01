/*
	libFM: Factorization Machines

	Based on the publication(s):
	Steffen Rendle (2010): Factorization Machines, in Proceedings of the 10th IEEE International Conference on Data Mining (ICDM 2010), Sydney, Australia.
	Steffen Rendle, Zeno Gantner, Christoph Freudenthaler, Lars Schmidt-Thieme (2011): Fast Context-aware Recommendations with Factorization Machines, in Proceedings of the 34th international ACM SIGIR conference on Research and development in information retrieval (SIGIR 2011), Beijing, China.

	Author:   Steffen Rendle, http://www.libfm.org/
	modified: 2011-07-14

	Copyright 2010-2011 Steffen Rendle, see license.txt for more information
*/

#include <cstdlib>
#include <cstdio>
#include <iostream>
#include <string>
#include <iterator>
#include <algorithm>
#include <iomanip>
#include "../util/util.h"
#include "../util/cmdline.h"
#include "../fm_core/fm_model.h"
#include "src/Data.h"
#include "src/fm_learn.h"
#include "src/fm_learn_sgd.h"
#include "src/fm_learn_sgd_element.h"
#include "src/fm_learn_als.h"
#include "src/fm_learn_als_simultaneous.h"


using namespace std;

int main(int argc, char **argv) { 
 	
 	srand ( time(NULL) );
	try {
		CMDLine cmdline(argc, argv);
		std::cout << "libFM" << std::endl;
		std::cout << "  Version: 1.10" << std::endl;
		std::cout << "  Author:  Steffen Rendle, srendle@ismll.de, http://www.libfm.org/" << std::endl;
		std::cout << "  License: Free for academic use. See license.txt." << std::endl;
		std::cout << "----------------------------------------------------------------------------" << std::endl;
		
		const std::string param_task		= cmdline.registerParameter("task", "r=regression, c=binary classification [MANDATORY]");
		const std::string param_train_file	= cmdline.registerParameter("train", "filename for training data [MANDATORY]");
		const std::string param_test_file	= cmdline.registerParameter("test", "filename for test data [MANDATORY]");
		const std::string param_out		= cmdline.registerParameter("out", "filename for output");

		const std::string param_dim		= cmdline.registerParameter("dim", "'k0,k1,k2': k0=use bias, k1=use 1-way interactions, k2=dim of 2-way interactions [MANDATORY]");
		const std::string param_regular		= cmdline.registerParameter("regular", "'r0,r1,r2': r0=bias regularization, r1=1-way regularization, r2=2-way regularization [MANDATORY]");
		const std::string param_init_stdev	= cmdline.registerParameter("init_stdev", "stdev for initialization of 2-way factors; default=0.01");
		const std::string param_num_iter	= cmdline.registerParameter("iter", "number of iterations for SGD; default=100");
		const std::string param_learn_rate	= cmdline.registerParameter("learn_rate", "learn_rate for SGD; default=0.1");
		const std::string param_method		= cmdline.registerParameter("method", "learning method (SGD or ALS); default=SGD");
	
		const std::string param_verbosity	= cmdline.registerParameter("verbosity", "how much infos to print; default=0");
		const std::string param_r_log		= cmdline.registerParameter("rlog", "write measurements within iterations to a file; default=''");
		const std::string param_help            = cmdline.registerParameter("help", "this screen");

		if (cmdline.hasParameter(param_help) || (argc == 1)) {
			cmdline.print_help();
			return 0;
		}
		cmdline.checkParameters();

		// (1) Load the data
		std::cout << "Loading train...\t";
		Data train;
		train.load(cmdline.getValue(param_train_file));
		if (cmdline.getValue(param_verbosity, 0) > 0) { train.debug(); }
		std::cout << "Loading test... \t";
		Data test;
		test.load(cmdline.getValue(param_test_file));
		if (cmdline.getValue(param_verbosity, 0) > 0) { test.debug(); }
		
		// (2) Setup the factorization machine
		fm_model fm;
		{
			fm.num_attribute = max(train.num_feature, test.num_feature);
			fm.init_stdev = cmdline.getValue(param_init_stdev, 0.01);
			// set the number of dimensions in the factorization
			{ 
				vector<int> dim = cmdline.getIntValues(param_dim);
				assert(dim.size() == 3);
				fm.k0 = dim[0] != 0;
				fm.k1 = dim[1] != 0;
				fm.num_factor = dim[2];					
			}
		
			
			fm.init();		
			// set the regularization
			{ 
	 			vector<double> reg = cmdline.getDblValues(param_regular);
				assert(reg.size() == 3);
				fm.reg0 = reg[0];
				fm.regw.init(reg[1]);
				fm.regv.init(reg[2]);					
			}
		}
		// (3) Setup the learning method:
		fm_learn* fml;
		if (! cmdline.getValue(param_method, "SGD").compare("sgd")) {
	 		fml = new fm_learn_sgd_element();
			((fm_learn_sgd*)fml)->num_iter = cmdline.getValue(param_num_iter, 100);
			((fm_learn_sgd*)fml)->learn_rate = cmdline.getValue(param_learn_rate, 0.1);			
		} else if (! cmdline.getValue(param_method).compare("als")) {
	 		fml = new fm_learn_als_simultaneous();
			((fm_learn_als*)fml)->num_iter = cmdline.getValue(param_num_iter, 100);
			if (cmdline.getValue("task").compare("r") ) {
				throw "ALS can only solve regression tasks.";
			}
		} else {
			throw "unknown method";
		}
		fml->fm = &fm;
		fml->max_target = train.max_target;
		fml->min_target = train.min_target;
		if (! cmdline.getValue("task").compare("r") ) {
			fml->task = 0;
		} else if (! cmdline.getValue("task").compare("c") ) {
			fml->task = 1;
			for (uint i = 0; i < train.target.dim; i++) { if (train.target(i) <= 0.0) { train.target(i) = -1.0; } else {train.target(i) = 1.0; } }
			for (uint i = 0; i < test.target.dim; i++) { if (test.target(i) <= 0.0) { test.target(i) = -1.0; } else {test.target(i) = 1.0; } }
		} else {
			throw "unknown task";
		}

		// (4) init the logging
		RLog* rlog = NULL;	 
		if (cmdline.hasParameter(param_r_log)) {
			ofstream* out_rlog = NULL;
			std::string r_log_str = cmdline.getValue(param_r_log);
	 		out_rlog = new ofstream(r_log_str.c_str());
	 		if (! out_rlog->is_open())	{
	 			throw "Unable to open file " + r_log_str;
	 		}
	 		std::cout << "logging to " << r_log_str.c_str() << std::endl;
			rlog = new RLog(out_rlog);
	 	}
	 	
		fml->log = rlog;
		fml->init();
		if (rlog != NULL) {
			rlog->init();
		}
		
		if (cmdline.getValue(param_verbosity, 0) > 0) { 
			fm.debug();			
			fml->debug();			
		}	

		// () learn		
		fml->learn(train, test);

		// () Prediction
		std::cout << "Final\t" << "Train=" << fml->evaluate(train) << "\tTest=" << fml->evaluate(test) << std::endl;	

		// () Save prediction
		if (cmdline.hasParameter(param_out)) {
			DVector<double> pred;
			pred.setSize(test.data.dim);
			fml->predict(test, pred);
			pred.save(cmdline.getValue(param_out));	
		}
				 	

	} catch (std::string &e) {
		std::cerr << e << std::endl;
	} catch (char const* &e) {
		std::cerr << e << std::endl;
	}

}
