#include <stddef.h>
#include "matrix.h"
#include "mex.h"

void subtract(const uint8_T *a, const uint8_T *b, mwSize m, mwSize n, int16_T *res) {
    int i, j;

    for(i = 0; i < m; i++) {
        for(j = 0; j < n; j++) {
            res[j + i*m] = a[j + i*m] - b[j + i*m]; 
            //mexPrintf("[%3d,%3d]: %d - %d = %d \n", i, j, a[j + i*m], b[j + i*m], res[j + i*m]);
        }
    }

}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    /*
     * Function takes a two arrays of the same size and subtracts them.
     */

    mwSize m,n;
    uint8_T *a, *b;

    if(nrhs != 2) {
        mexErrMsgTxt("Need two matricies to subtract\n");
    }

    if(mxGetM(prhs[0]) != mxGetM(prhs[1]) || mxGetN(prhs[0]) != mxGetN(prhs[1])) {
        mexErrMsgTxt("Dimensions of arguments must agree\n");
    }

    if(!mxIsUint8(prhs[0]) || !mxIsUint8(prhs[1])) {
        mexErrMsgTxt("Arguments must be of class uint8\n");
    }
    
    m = mxGetM(prhs[0]);
    n = mxGetN(prhs[0]);

    plhs[0] = mxCreateNumericMatrix(m, n, mxINT16_CLASS, mxREAL);
    a = (uint8_T *)mxGetData(prhs[0]);
    b = (uint8_T *)mxGetData(prhs[1]);

    subtract(a, b, m, n, mxGetPr(plhs[0])); 
}

