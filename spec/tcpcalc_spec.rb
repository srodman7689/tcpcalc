require 'spec_helper'

describe "TCPCalc", :acceptance do 
  before(:all) do
    @server_thread = Thread.new do
      TCPCalc::Server.new(TCPCalc::PORT).listen
    end
    wait_for_open_port(TCPCalc::PORT)

  end

  after(:all) do
    Thread.kill(@server_thread) if @server_thread
  end

  def is_numeric?(s)
    !!Integer(s) rescue false
  end

  it 'responds with a number' do
    s = client
    s.write("GET\r\n")
    response = s.gets
    s.close
    expect(true).to eq(is_numeric?(response))
  end

  it 'adds n to a number when sending the add command' do
    s = client
    s.write("GET\r\n")
    first_num = s.gets
    s.write("ADD 1\r\n")
    s.gets
    s.write("GET\r\n")
    second_num = s.gets
    s.close
    expect(true).to eq(is_numeric?(first_num))
    expect(true).to eq(is_numeric?(second_num))
    expect(first_num.to_i+1).to eq(second_num.to_i)
  end

  it 'subtracts n from a number when sending the subtract command' do
    s = client
    s.write("GET\r\n")
    first_num = s.gets
    s.write("SUBTRACT 1\r\n")
    s.gets
    s.write("GET\r\n")
    second_num = s.gets
    s.close
    expect(true).to eq(is_numeric?(first_num))
    expect(true).to eq(is_numeric?(second_num))
    expect(first_num.to_i-1).to eq(second_num.to_i)
  end

  it 'allows multiple simultaneous connections' do
    first_client = client
    second_client = client
    first_client.write("GET\r\n")
    second_client.write("GET\r\n")
    first_response = first_client.gets
    second_response = second_client.gets
    first_client.close
    second_client.close
    expect(first_response).to match(/[0-9]\n/)
    expect(second_response).to match(/[0-9]\n/)
    expect(first_response).to_not eq(second_response)
  end

  it 'closes the connection when sending exit' do
    s = client
    s.write("EXIT\r\n")
    response = s.gets
    s.close
    expect(response).to eq(nil)
  end

  it 'responds with invalid command when sent any other command' do
    s = client
    s.write("INVALID\r\n")
    response = s.gets
    s.close
    expect(response).to eq("invalid command\n")
  end

  it 'responds with invalid command when adding a non-numeric value' do
    s = client
    s.write("ADD S\r\n")
    response = s.gets
    s.close
    expect(response).to eq("invalid command\n")
  end

  it 'responds with invalid command when subtracting a non-numeric value' do
    s = client
    s.write("SUBTRACT S\r\n")
    response = s.gets
    s.close
    expect(response).to eq("invalid command\n")
  end

  it 'responds with invalid command when adding a float' do
    s = client
    s.write("ADD 1.1\r\n")
    response = s.gets
    s.close
    expect(response).to eq("invalid command\n")
  end

  it 'responds with invalid command when subtracting a float' do
    s = client
    s.write("SUBTRACT 1.1\r\n")
    response = s.gets
    s.close
    expect(response).to eq("invalid command\n")
  end

  def wait_for_open_port(port)
    time = Time.now
    while !check_port(port) && 1 > Time.now - time
      sleep 0.01
    end

    raise TimeoutError unless check_port(port)
  end

  def check_port(port)
    begin
      s = client
      s.close
      return true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      return false
    end
  end

  def client
    TCPSocket.new('localhost', TCPCalc::PORT)
  end
end