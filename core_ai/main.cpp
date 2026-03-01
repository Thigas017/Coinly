#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>

using namespace cv;
using namespace std;

int main() {
    VideoCapture cap(0);

    if (!cap.isOpened()) {
        cout << "Error: Cannot open camera." << endl;
        return -1;
    }

    cout << "Coin detection mode active. Press ESC to exit." << endl;

    Mat frame, gray;

    while (true) {
        cap.read(frame);
        if (frame.empty()) {
            cout << "Error: Empty frame." << endl;
            break;
        }

        //Convert color image to grayscale
        cvtColor(frame, gray, COLOR_BGR2GRAY);

        //Apply Gaussian blur to reduce noise and background textures
        GaussianBlur(gray, gray, Size(9, 9), 2, 2);

        //Detect circular shapes using the Hough Circle Transform
        vector<Vec3f> circles; //Stores detected circle parameters (x, y, radius)

        HoughCircles(gray, circles, HOUGH_GRADIENT,
                     1, gray.rows / 8, //Minimum distance between detected circles
                     150, 60,          //Detection sensitivity thresholds
                     15, 200);         //Minimum and maximum radius (in pixels)

        //Draw detected circles on the original frame
        for (size_t i = 0; i < circles.size(); i++) {
            Point center(cvRound(circles[i][0]), cvRound(circles[i][1])); //Circle center
            int radius = cvRound(circles[i][2]);                          //Circle radius

            //Draw red dot at circle center
            circle(frame, center, 3, Scalar(0, 0, 255), -1, 8, 0);

            //Draw green outline around detected circle
            circle(frame, center, radius, Scalar(0, 255, 0), 3, 8, 0);
        }

        //Display processed frame with overlays
        imshow("Coinly - Detecao de Moedas", frame);

        //Exit loop if ESC key (27) is pressed
        if (waitKey(30) == 27) {
            cout << "Closing camera..." << endl;
            break;
        }
    }

    cap.release();
    destroyAllWindows();
    return 0;
}