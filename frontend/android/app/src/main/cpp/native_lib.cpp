#include <opencv2/opencv.hpp>
#include <vector>
#include <stdint.h>

//Export function visibility for Android/Linux so Flutter can access it
#define FFI_EXPORT __attribute__((visibility("default"))) __attribute__((used))

extern "C" {

    //Keep the test function returning 42 for validation purposes
    FFI_EXPORT int test_connection() {
        return 42;
    }

    //Primary coin detection function
    FFI_EXPORT int detect_coin(uint8_t* image_bytes, int width, int height, float* out_circle) {

        //Convert raw camera bytes from Flutter into an OpenCV matrix
        cv::Mat gray(height, width, CV_8UC1, image_bytes);

        //Apply Gaussian blur to reduce image noise
        cv::GaussianBlur(gray, gray, cv::Size(9, 9), 2, 2);

        //Perform Hough Circle Transform to detect circular shapes
        std::vector<cv::Vec3f> circles;
        cv::HoughCircles(gray, circles, cv::HOUGH_GRADIENT,
                         1, gray.rows / 8,
                         150, 60,
                         15, 200);

        //Check if any circles were detected
        if (!circles.empty()) {
            //Store X, Y coordinates and radius of the first detected circle
            out_circle[0] = circles[0][0];
            out_circle[1] = circles[0][1];
            out_circle[2] = circles[0][2];
            return 1; //1 indicates success
        }

        return 0; //0 indicates no coin detected
    }

    /*//Simple test function to validate native library connection
    FFI_EXPORT int test_connection() {
        return 42;
    }*/
}