#include <opencv2/opencv.hpp>
#include <vector>

//Cross-platform export definition for Windows and other platforms
//Windows and Android use different keywords to export functions
#ifdef _WIN32
    #define FFI_EXPORT __declspec(dllexport)
#else
    #define FFI_EXPORT __attribute__((visibility("default")))
#endif

extern "C" { //Prevent name mangling so Flutter can locate the function

    //Function called from Flutter via FFI
    //Receives: Grayscale image bytes, width, and height
    //Returns: 1 if a coin is detected, 0 otherwise
    //Outputs: Circle data (center X, center Y, radius) through out_circle
    FFI_EXPORT int detect_coin(unsigned char *image_bytes, int width, int height, float *out_circle) {

        //Convert raw image bytes into an OpenCV matrix
        cv::Mat gray(height, width, CV_8UC1, image_bytes);

        //Apply Gaussian blur to reduce noise
        cv::GaussianBlur(gray, gray, cv::Size(9, 9), 2, 2);

        //Perform Hough Circle Transform for circle detection
        std::vector<cv::Vec3f> circles;
        cv::HoughCircles(gray, circles, cv::HOUGH_GRADIENT,
                         1, gray.rows / 8,
                         150, 60,
                         15, 200);

        //Check if any circles were detected
        if (!circles.empty()) {
            //Return the first detected circle
            out_circle[0] = circles[0][0]; //Center X
            out_circle[1] = circles[0][1]; //Center Y
            out_circle[2] = circles[0][2]; //Radius

            return 1; //Detection successful
        }
        return 0; //No coin detected
    }
}