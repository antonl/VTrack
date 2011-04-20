#include <stddef.h>
#include "matrix.h"
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    /*
     * Function takes a two arrays of the same size and subtracts them.
     */
    /*
    */
    mwSize n, m; // Contains dimensions of array 
    mxArray *sans_bg; // Subtracted background
    uint8_T *i1, *i2; // Pointers to actual input data
    int16_T *res_data; // Pointer to resultant data

    mwSize linsub[2], i;

    if(nrhs != 2) {
        mexErrMsgTxt("Need two matricies to subtract\n");
    }

    if(mxGetM(prhs[0]) != mxGetM(prhs[1]) || mxGetN(prhs[0]) != mxGetN(prhs[1])) {
        mexErrMsgTxt("Dimensions of arguments must agree\n");
    }

    if(!mxIsUint8(prhs[0]) || !mxIsUint8(prhs[1])) {
        mexErrMsgTxt("Arguments must be of class uint8\n");
    }
    
    n = mxGetN(prhs[0]);
    m = mxGetM(prhs[0]);

    plhs[0] = mxCreateNumericMatrix(n,m, mxINT16_CLASS, mxREAL);

    i1 = (uint8_T *)mxGetData(prhs[0]);
    i2 = (uint8_T *)mxGetData(prhs[1]);

    res_data = (int16_T *)mxGetData(plhs[0]);

    for(linsub[0] = 0; linsub[0] < m; linsub[0]++) {
        for(linsub[1] = 0; linsub[1] < n linsub[1]++) {
            i = mxCalcSingleSubscript(prhs[0], 2, linsub);   
            res_data[i] = (int16_T)i1[i] - (int16_T)i2[i];
            mexPrintf("%u\t",res_data[i]);  
        }
    }

}
