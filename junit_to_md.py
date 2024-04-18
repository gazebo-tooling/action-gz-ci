import sys
from xml.etree import ElementTree as ET

print('| Status | Name | Tests | Failures | Disabled | Skipped | Errors | Time |')
print('| ------ | ---- | ----- | -------- | -------- | ------- | ------ | ---- |')
docs = []
for file in sys.argv[1:]:
    doc = ET.parse(file)
    docs.append(doc)
    for testsuite in doc.findall('testsuite'):
        if int(testsuite.attrib['failures']) > 0:
            status = "Failed ❌"
        else:
            status = "Passed ✅"
        print('| {status} | {name} | {tests} | {failures} | {disabled} | {skipped} | {errors} | {time} |'.format(status=status, **testsuite.attrib))


print()

for doc in docs:
    for testsuite in doc.findall('testsuite'):
        print(f'<details><summary>{testsuite.attrib["name"]}</summary>\n')
        print('| Status | Name | Time |')
        print('| ------ | ---- | ---- |')
        for testcase in doc.findall('testsuite/testcase'):
            failures = testcase.findall('failure')
            failed = len(failures) > 0
            if failed:
                status = "Failed ❌"
            else:
                status = "Passed ✅"
            print("| {fail_status} |{classname}.{name} | {time} |".format(**testcase.attrib, fail_status=status))

        print()
        for testcase in doc.findall('testsuite/testcase'):
            failures = testcase.findall('failure')
            if len(failures) > 0:
                print('<details><summary>Failure messages for {classname}.{name}</summary>'.format(**testcase.attrib))
                print('\n```sh')
                for failure in failures:
                    print(failure.attrib['message'])
                print('```\n')
                print('</details>')
        print('</details>\n')

