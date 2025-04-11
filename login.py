import requests

# just console for now
def prompt_data():
    username = input("Please enter username: ")
    password = input ("Please enter password: ")
    send_data(username, password)

def send_data(username, password):
    response = requests.post('https://expant-backend.onrender.com/login', json={'username': username, 'password': password})

if __name__=="__main__":
    prompt_data()