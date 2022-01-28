# from dateutil.tz.tz import gettz
from iqoptionapi.stable_api import IQ_Option
from yachalk import chalk
import sys
import time
from datetime import datetime, tzinfo
import sys
import os
import threading
from dotenv import load_dotenv



API = IQ_Option(os.getenv("IQOPTIONLOGIN"), os.getenv("IQOPTIONPASS"))

# PARAMETERS
start_bet_value = 3
max_bet_value = 7
stop_win = 30000
stop_loss = -15000
stop_win = 50
stop_loss = -50
risk_value = 2  # 2-3 Risky 4-5 Moderate
balance_mode = 'PRACTICE'  # PRACTICE / REAL
candle_size = 60  # 1 minute
time_to_update = 3600  # in seconds

# GLOBALS
balance = 0
active_margintale = False
open_streamings = []
f = None


def validade_pair(pair):
    possible_pairs = ['USDCAD', 'EURGBP', 'GBPUSD', 'USDJPY',
                      'USDCHF', 'GBPJPY', 'EURUSD', 'EURJPY', 'AUDUSD', 'AUDJPY',
                      'USDCAD-OTC', 'EURGBP-OTC', 'GBPUSD-OTC', 'USDJPY-OTC',
                      'USDCHF-OTC', 'GBPJPY-OTC', 'EURUSD-OTC', 'EURJPY-OTC', 'AUDUSD-OTC', 'AUDJPY-OTC']

    if pair in possible_pairs:
        return True

    return False


def now():
    return chalk.gray(time.strftime('%H:%M:%S', time.gmtime()) + ' ')


def money(value):
    value = 'R$ ' + f'{value:.2f}'
    return str(value)


def timestamp_converter(timestamp):
    hour = datetime.strptime(datetime.utcfromtimestamp(
        timestamp).strftime('%Y-%m-%d %H:%M:%S'), '%Y-%m-%d %H:%M:%S')

    # hour = hour.replace(tzinfo=tz.gettz('GMT'))

    # return (hour.astimezone(tz.gettz('America/Sao Paulo'))).strftime('%H:%M:%S')
    # return str(hour.astimezone(tz.gettz('America/Sao Paulo')))[:-6]
    return str(hour)


def start_martingale(pair, next_op):
    global active_margintale

    active_margintale = True
    buy(start_bet_value, pair, next_op)


def buy(value, pair, next_op):
    global balance, active_margintale

    _, id = API.buy(value, pair, next_op, 1)

    next_op_collored = None

    if next_op == 'call':
        next_op_collored = chalk.green_bright('CALL')
    else:
        next_op_collored = chalk.red_bright('PUT')

    print(now() + chalk.yellow_bright("OPERATION [" + str(id) + '] ') +
          chalk.cyan(pair) + ' - ' + next_op_collored + ' - ' + chalk.yellow_bright(money(value)))

    while API.check_win_v3(id) == None:
        pass
    profit = API.check_win_v3(id)

    balance_collored = None
    balance = balance + profit

    if (balance >= stop_win or balance <= stop_loss):  # Exiting program (stop loss/stop win)
        active_margintale = False
        sys.exit()

    if balance > 0:
        balance_collored = chalk.green_bright(money(balance))
    elif balance < 0:
        balance_collored = chalk.red_bright(money(balance))
    else:
        balance_collored = chalk.grey(money(balance))

    if profit > 0:  # stop martingale afiter win
        active_margintale = False
        print(now() + chalk.yellow_bright("OPERATION [" + str(id) + '] ') + chalk.green_bright("WIN!") + ' ' +
              money(profit) + ' - Balance: ' + balance_collored)
    elif profit == 0:  # stop martingale after doji
        active_margintale = False
        print(now() + chalk.yellow_bright("OPERATION [" + str(id) + '] ') + chalk.gray(
            'DOJI') + ' - Balance: ' + balance_collored)
    else:
        print(now() + chalk.yellow_bright("OPERATION [" + str(id) + '] ') + chalk.red_bright("LOSS!") + ' ' +
              money(profit) + ' - Balance: ' + balance_collored)
        if value < max_bet_value:
            value = update_current_bet_value(value)
            buy(value, pair, next_op)
        else:
            active_margintale = False


def str_format_candle(pair, candle):
    color = 'DOJI'
    if candle['open'] > candle['close']:
        color = chalk.red_bright('PUT')
    elif candle['open'] < candle['close']:
        color = chalk.green_bright('CALL')

    line = chalk.cyan(pair) + ' ' + chalk.blue_bright('[' + str(candle['id']) + '] ') + \
        color + ' - Open: ' + \
        str(candle['open']) + ' Close: ' + str(candle['close'])
    return line


def update_current_bet_value(current_bet_value):
    if current_bet_value == 3:
        current_bet_value = 5
    elif current_bet_value == 5:
        current_bet_value = 8

    # if current_bet_value == 2:
    #     current_bet_value = 3
    # else:
    #     if (current_bet_value * 3 <= max_bet_value):
    #         current_bet_value = current_bet_value * 3

    return current_bet_value


def start_candle_streaming(pair):
    global active_margintale

    print('')
    print(now() + 'Starting ' + chalk.cyan(pair) + ' streaming...')

    API.start_candles_stream(pair, candle_size, 2)

    open_streamings.append(pair)

    candles = API.get_realtime_candles(pair, candle_size)

    call_count = 0
    put_count = 0
    next_op = None
    last_candle_id = 0
    current_op_id = 0
    current_bet_value = start_bet_value
    stream_running_for = 0  # seconds
    thread_pair = None

    while pair in open_streamings and stream_running_for < time_to_update:
        for candle, _ in list(candles.items()):
            if candles[candle]['to'] <= time.time():

                if last_candle_id < candles[candle]['id']:
                    last_candle_id = candles[candle]['id']

                    open = candles[candle]['open']
                    close = candles[candle]['close']

                    openstr = '{:<08f}'.format(open).replace('.', '')
                    closestr = '{:<08f}'.format(close).replace('.', '')

                    open = int(openstr)
                    close = int(closestr)

                    diff = abs(close - open)

                    if candles[candle]['close'] < candles[candle]['open'] and diff > 50:  # PUT
                        next_op = 'call'
                        call_count = 0
                        put_count = put_count + 1
                    elif candles[candle]['close'] > candles[candle]['open'] and diff > 50:  # CALL
                        next_op = 'put'
                        call_count = call_count + 1
                        put_count = 0
                    else:  # DOJI
                        call_count = 0
                        put_count = 0

                    print(now() + str_format_candle(pair, candles[candle]) + ' - CALLS: ' + str(
                        call_count) + ' PUTS: ' + str(put_count) + ' Size: ' + str(diff))

                    if active_margintale == False:
                        if (call_count >= risk_value or put_count >= risk_value):
                            if (current_op_id == candles[candle]['id']):
                                current_bet_value = update_current_bet_value(
                                    current_bet_value)
                            else:
                                current_bet_value = start_bet_value

                            current_op_id = candles[candle]['id'] + 1

                            if active_margintale == False:
                                call_count = 0
                                put_count = 0

                                thread_pair = threading.Thread(
                                    target=start_martingale, args=(pair, next_op,))
                                thread_pair.start()

            time.sleep(1)
            stream_running_for += 1

    API.stop_candles_stream(pair, "all")


def connect_to_iqoption():
    print('')
    print(now() + 'Connecting to server...')
    API.connect()

    if API.check_connect():
        print(now() + 'Connected!')
    else:
        print(now() + 'ERROR connecting')
        sys.exit()


def change_balance():
    print(now() + 'Changing balance mode to ' +
          chalk.yellow_bright(balance_mode))
    API.change_balance(balance_mode)
    print(now() + 'Account balance: ' +
          chalk.yellow_bright(money(API.get_balance())))

    print(now() + 'Starting Robot Balance at ' +
          chalk.yellow_bright(money(balance)))


def get_most_profitable_pair():
    profits = API.get_all_profit()

    most_profitable_pair = None
    most_profitable_value = 0

    print('')
    print(now() + 'Getting OPEN options...')
    pairs = API.get_all_open_time()

    print(now() + 'Selecting most profitable pair...')
    for pair in pairs['turbo']:
        if pairs['turbo'][pair]['open'] == True and validade_pair(pair):
            profit = int(100 * profits[pair]['turbo'])
            if most_profitable_value < profit:
                most_profitable_pair = pair
                most_profitable_value = profit

    if most_profitable_pair == None:
        print(now() + chalk.red_bright('Pairs are unavailable at the moment... Exiting robot.'))
        # sys.exit
    else:

        print(now() + 'Most profitable pair: ' + chalk.cyan(most_profitable_pair) +
              ' - ' + chalk.yellow_bright(str(most_profitable_value) + '%'))

    return most_profitable_pair

connect_to_iqoption()

change_balance()

open_streamings = []

print(now() + 'Creating operation mechanism...')

while True:
    # Only update pair if Martingale is not currently running.
    if active_margintale == False:
        print(now() + 'Updating pairs...')

        print(now() + 'Unsubscribing to previus pairs...')
        for stream in open_streamings:
            print(now() + 'Unsubscribing to ' + chalk.cyan(stream))
            API.stop_candles_stream(stream, "all")

        pair = get_most_profitable_pair()

        if pair != None:
            start_candle_streaming(pair)
            open_streamings = []
