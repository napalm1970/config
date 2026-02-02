import csv
import subprocess
import os

csv_file = os.path.expanduser('~/password.csv')

with open(csv_file, mode='r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        group = row['Group'].strip('"')
        title = row['Title'].strip('"')
        password = row['Password'].strip('"')
        username = row['Username'].strip('"')
        url = row['URL'].strip('"')
        notes = row['Notes'].strip('"')

        # Construct path: Group/Title
        pass_path = os.path.join(group, title)

        # Prepare content
        content = f"{password}\nUsername: {username}\nURL: {url}\nNotes: {notes}"

        print(f"Importing: {pass_path}")

        # Call pass insert
        # --multiline or just pipe
        process = subprocess.Popen(['pass', 'insert', '-m', pass_path],
                                   stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE,
                                   text=True)
        stdout, stderr = process.communicate(input=content)
        if process.returncode != 0:
            print(f"Error importing {pass_path}: {stderr}")
