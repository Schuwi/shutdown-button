from RPi import GPIO
import time
import os

def main():
    GPIO.setmode(GPIO.BOARD)
    GPIO.setup(40, GPIO.IN, pull_up_down=GPIO.PUD_UP)

    print("Waiting for pin to be LOW")
    # wait until pin is in expected "running" state
    while GPIO.input(40) == 1:
        time.sleep(0.5)

    print("Waiting for shutdown request (pin HIGH)")
    time.sleep(1)
    # wait for shutdown request
    while GPIO.input(40) == 0:
        GPIO.wait_for_edge(40, GPIO.RISING)
        # sleep before checking again to avoid glitches
        time.sleep(0.5)

    print("Shutting down system...")
    os.system("/sbin/shutdown -h now")
