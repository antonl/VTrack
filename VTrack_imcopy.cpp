#include "matrix.h"
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    /*
     * Function takes a two arrays of the same size and subtracts them.
     */
    double hImage;
    const mxArray *CData;

    if(nrhs != 2) {
        mexErrMsgTxt("Need two matricies as inputs\n");
    }

    // Get handle to hImage object
    hImage = mxGetScalar(prhs[0]);

    mexSet(hImage, "CData", mxDuplicateArray(prhs[1]));    
    
}


