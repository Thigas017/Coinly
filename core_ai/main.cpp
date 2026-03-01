#include <opencv2/opencv.hpp>
#include <iostream>

using namespace cv;
using namespace std;

int main() {
    //Attempt to open the default camera (device 0)
    VideoCapture cap(0);

    //Verify camera initialization
    if (!cap.isOpened()) {
        cout << "Error: Cannot open camera." << endl;
        return -1;
    }

    cout << "Camera started. Press ESC to exit." << endl;

    Mat frame; //OpenCV matrix used to store image data

    //Main capture loop
    while (true) {
        cap.read(frame); //Capture current frame

        if (frame.empty()) {
            cout << "Error: Empty frame." << endl;
            break;
        }

        //Display frame in project window
        imshow("Coinly - Teste de Visao (OpenCV)", frame);

        //Wait 30ms; exit on ESC (27)
        if (waitKey(30) == 27) {
            cout << "Shutting down camera..." << endl;
            break;
        }
    }

    //Release camera and destroy windows
    cap.release();
    destroyAllWindows();
    return 0;
}