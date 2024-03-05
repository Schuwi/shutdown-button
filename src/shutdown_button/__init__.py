import gpiod
from gpiod.edge_event import EdgeEvent
from gpiod.line import Bias, Direction, Edge, Value
from datetime import timedelta
import time
import os

# GPIO 21 is PIN 40 on Raspberry Pi
LINE = 21
LINE_SETTINGS = gpiod.LineSettings(direction=Direction.INPUT,
                    bias=Bias.PULL_UP,
                    edge_detection=Edge.BOTH,
                    # with shorter debounce there are erroneous events triggered on jumper reinsertion
                    debounce_period=timedelta(milliseconds=200)
                )

def clear_events(request):
    if request.wait_edge_events(timeout=timedelta(0)):
        request.read_edge_events()

def wait_for_edge_event(request, typ):
    while True:
        for event in request.read_edge_events():
            if event.event_type == typ:
                return

def main():
    with gpiod.request_lines(
        "/dev/gpiochip0",
        consumer="shutdown_button",
        config={
            LINE: LINE_SETTINGS
        }
    ) as request:
        # wait until pin is in expected "running" state
        print("Waiting for pin to be LOW")

        # clear events before value check to avoid race condition
        clear_events(request)
        while request.get_value(LINE) == Value.ACTIVE:
            wait_for_edge_event(request, EdgeEvent.Type.FALLING_EDGE)
        
        print("Waiting for shutdown request (pin HIGH)")
        time.sleep(1)
        # wait for shutdown request
        clear_events(request)
        while request.get_value(LINE) == Value.INACTIVE:
            wait_for_edge_event(request, EdgeEvent.Type.RISING_EDGE)
        
        print("Shutting down system...")
        os.system("/sbin/shutdown -h now")
