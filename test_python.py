# Test Python file for syntax highlighting
import os
import sys
from datetime import datetime

def main():
    """Main function to test syntax highlighting"""
    print("Testing Python syntax highlighting")
    
    # Test various keywords
    if True:
        x = 10
        for i in range(x):
            print(f"Count: {i}")
    
    try:
        result = 42 / 2
    except ZeroDivisionError:
        pass
    
    return result

class TestClass:
    def __init__(self):
        self.value = "test"
    
    def method(self):
        return self.value

if __name__ == "__main__":
    main()