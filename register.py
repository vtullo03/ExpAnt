import requests
import login

# just console for now
def send_data(username, password, is_organization=False):
    requests.post(
        'https://expant-backend.onrender.com/register',
        json={'username': username, 'password': password, 'is_organization': is_organization}
    )
    login.send_data(username, password)

def prompt_data():
    username = input("Please enter username: ")
    password = input("Please enter password: ")
    is_org_input = input("Is this an organization account? (y/n): ").strip().lower()
    is_org = is_org_input == 'y'
    send_data(username, password, is_org)


def create_match_profile():
    print("Time to create your profile")
    bio = input("Bio: ")
    images = input("Images: ")
    interests = input("Interests: ")
    font_color = input("Font Color: ")
    background_color = input("Background Color: ")
    font_type = input("Font Type: ")
    requests.post('http://127.0.0.1:5000/match_profile', json={'bio': bio, 'images': images, 'interests': interests, 'font_color': font_color, 'background_color': background_color, 'font_type': font_type})

if __name__=="__main__":
    prompt_data()