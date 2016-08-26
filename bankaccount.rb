require 'Faker'
require 'csv'
#require 'awesome_print'
require 'time'
require 'money'


module Interest
	def add_interest_rate(rate)
		interest=(@balance*(rate/100)).to_i
		@balance+=interest
		return interest
	end
end

class Fixnum
	def to_money
		return Money.new(self,"USD").format
	end
end

module Bank
	class Owner
		@@used_ids=[]
		@@owners=[]
		attr_accessor :name, :address, :phone_number, :id
		
		def initialize(id,name,address,phone_number)
			@name=name #array of [first name, last name]
			@address=address #hash of address street,city,state,zip
			@phone_number=phone_number
			@id=id #generate_id
			@@owners<<self
			Owner.add_to_csv
			#probably need to make a separate method for this...	
		end

		def self.create_from_csv(csv_name)
			owners_csv=CSV.open(csv_name,'r')
			owners_csv.shift
			
			owners_csv.each do |row|
				Owner.new(row[0],row[1],row[2],row[3])
			end
		end

		def self.all
			return @@owners
		end

		def self.find(id)
			self.all.each do |account|
				if account.id==id
					puts account.id
					puts account
					return account
				end
			end
		end

		def self.add_to_csv
			CSV.open("current_owners.csv","a") do |csv|
				@@owners.each do |owner|
					csv<<[owner.id,owner.name.last,owner.name.first,owner.address[:street1],owner.address[:city],owner.address[:state],owner.phone_number]
				end
			end
		end

		#this solution doesn't scale for systems in which I need a HUGE number of ids
		#because it would be stuck in an infinite loop when it runs out of ids
		def self.generate_id
			potential_id=rand(1111111..9999999).to_s
			until not (@@used_ids.include?(potential_id))  do #generate ids until you get unused one
				potential_id=rand(111111..999999).to_s
			end
			@@used_ids<< potential_id
			return potential_id
		end

		def self.generate_fake_owner
			id=self.generate_id
			Owner.new(id,[Faker::Name.first_name,Faker::Name.last_name],{street1:Faker::Address.street_address, street2: "", city: Faker::Address.city, state: Faker::Address.state, zip:Faker::Address.zip},Faker::PhoneNumber.phone_number)
		end

		def accounts
			my_accounts=[]
			accountsCSV=CSV.open("account_owners.csv","r")
			accountsCSV.shift #maybe I can do csv.open.shift
			
			accountsCSV.each do |row|
				if @id==row[1]
					my_accounts << Bank::Account.find(row[0])
				end
			end
			return my_accounts
		end
	end

	class Account
		@@used_ids=[]
		@@accounts=[]
		attr_reader :balance, :id, :open_date, :owner
		
		def initialize(id,balance,open_date,owner)
			raise ArgumentError, "You cannot open a bank account with a negative balance" unless balance.to_i>0
			@minimum_balance=0
			@balance=balance.to_i
			#@id=generate_id
			@id=id
			if open_date.class == String
				@open_date=Time.parse(open_date)#DateTime.now
			else
				@open_date=open_date
			end
			@owner=owner
			@@accounts<<self

			CSV.open("account_owners.csv", 'a') do |csv|
				csv<<[@id, owner.id]
			end


			CSV.open("current_accounts.csv", 'a') do |csv|
				csv<<[@id,@balance,@open_date]
			end
			puts "You have a new bank account with id: #{@id} balance: #{balance.to_money}"
			
		end

		def self.create_from_csv(csv_name)
			accounts_csv=CSV.open(csv_name,'r')
			accounts_csv.shift
			accounts_csv.each do |row|
				@@accounts << Bank::Account.new(row[0],row[1],row[2],Bank::Owner.new([Faker::Name.first_name,Faker::Name.last_name],{street1:Faker::Address.street_address, street2: "", city: Faker::Address.city, state: Faker::Address.state, zip:Faker::Address.zip},Faker::PhoneNumber.phone_number))
			end
		end

		def self.all 
			return @@accounts
		end

		def self.find(id)
			#probably can do @@accounts here
			self.all.each do |account|
				if account.id==id
					#puts account.id
					#puts account
					return account
				end
			end
			#would like to throw an error here instead
			puts "Could not find a bank account with id: #{id}"
		end

		#would like to figure out a way to reuse code between two classes. like share this method only
		def generate_id
			potential_id=rand(1111111..9999999).to_s
			until not (@@used_ids.include?(potential_id))  do #generate ids until you get unused one
				potential_id=rand(111111..999999).to_s
			end
			@@used_ids<< potential_id
			return potential_id
		end

		def withdraw(amount)
			potential_balance=@balance-amount
			if potential_balance<@minimum_balance
				puts "Sorry, this withdrawl will cause the account to have a balance below #{minimum_balance.to_money}. Please try again."
				return balance
			else
				return @balance-=amount
			end
		end

		def deposit(amount)
			if amount<0
				puts "Sorry you cannot withdraw a negative amount"
				return balance
			else	
				return @balance+=amount
			end
		end
	end
	
	class SavingsAccount < Account
		include Interest
		def initialize(id,balance,open_date,owner)
			raise ArgumentError, "You need at least $10 to open a bank account" unless balance.to_i>1000
			super
			@minimum_balance=1000
		end
		
		def withdraw(amount)
			fee=200
			@balance-=fee
			new_balance=super
			if new_balance == @balance
				@balance+=fee
			end
			return @balance
		end
		
	end
	
	class CheckingAccount < Account
		alias_method :parent_withdraw, :withdraw
		
		def initialize(id,balance,open_date,owner)
			@minimum_balance=0
			reset_checks
			super
		end

		def withdraw(amount)
			fee=100
			@balance-=fee
			new_balance=super
			if new_balance == @balance
				@balance+=fee
			end
			return @balance
		end

		def withdraw_using_check(amount)
			original_min=@minimum_balance
			@minimum_balance=-10
			@checks+=1

			if @checks>3
				fee=200
			else
				fee=0
			end

			@balance-=fee
			new_balance=parent_withdraw(amount)
			if new_balance == @balance
				@balance+=fee
			end
			return @balance

			@minimum_balance=original_min
		end

		def reset_checks
			@checks=0
		end
	end
	
	class MoneyMarketAccount<Account
		attr_reader :transactions
		include Interest
		def initialize(id,balance,open_date,owner)
			super
			@transactions=0
			@minimum_balance=1000000
			raise ArgumentError, "You need at least $10,000 to open a money market account" unless balance.to_i>@minimum_balance-1
			@locked_account=false
		end

		def withdraw(amount)
			if not too_many_transactions?
				if not @locked_account 
					original_min=@minimum_balance
					@minimum_balance=0
					super
					@minimum_balance=original_min
					@transactions+=1
					puts "The transaction went through"
					if @balance<@minimum_balance
						fee=10000
						puts "You have been charged $100 for allowing your account balance to fall below the minimum balance"
						@balance-=fee
						lock_account
					end
				else
					lock_account
					return @balance
				end
				return @balance
			end
			return @balance
		end

		def lock_account
			if not @locked_account
				@locked_account=true
			end
			puts "Your account has been locked due to insufficient funds for further withdrawls. Your current balance is $#{@balance/100.0}"
			puts "Please deposit #{(@minimum_balance-@balance).to_money} to unlock your account."
		end

		def deposit(amount)
			if not too_many_transactions?
				if @locked_account and (@balance+amount>=@minimum_balance)
					@locked_account=false
				else 
					@transactions+=1
				end
				super
			end
			return @balance
		end

		def too_many_transactions?
			if @transactions>6
				puts "You cannot perform anymore transactions on this account until next month"
				return true
			end
			return false
		end

		def reset_transactions
			@transactions=0
		end
	end
end

#account=Bank::Account.new("1234567","500","2016-08-23T13:08:23-07:00",quai)
# my_account=Bank::Account.new(quai,300) 
# my_account.withdraw(301) 
# account2=Bank::Account.new(quai,80000) 
# account2.deposit(40)

# Bank::Account.create_from_csv('bankdata.csv')


# Bank::Account.all.each do |this_account|     
# 	puts "Name:
# #{this_account.owner.name}\nID:#{this_account.id}\nBalance: #{this_account.balance} " #
# end


# To test .find method. This puts 500
# puts Bank::Account.all
# puts Bank::Account.find("1234567").balance

#This should say cannot find that id. then throw error because you can't
#get a balance from an account that doesn't exist
# #puts Bank::Account.find("00").balance




# CSV.open("bankdata.csv",'a') do |csv|
# 	csv<<[my_account.id,my_account.balance,my_account.open_date]
# 	csv<<[account2.id,account2.balance,account2.open_date]
# end

# 5.times do
# 	CSV.open("owners.csv",'a') do |csv|
# 		new_owner=Bank::Owner.generate_fake_owner
# 		csv<<[new_owner.id,new_owner.name.last,new_owner.name.first,new_owner.address[:street1],new_owner.address[:city],new_owner.address[:state], new_owner.phone_number]
# 	 end
# end
# puts Bank::Owner.all

#to test .create_from_csv method
#Bank::Owner.create_from_csv('owners.csv')




# #make a fake version of me (an owner) using address and phone number from faker
#fake_name=[Faker::Name.first_name,Faker::Name.last_name]
address={street1:Faker::Address.street_address, street2: "", city: Faker::Address.city, state: Faker::Address.state, zip:Faker::Address.zip}
phone_number=Faker::PhoneNumber.phone_number
quai=Bank::Owner.new("3333333",["Quai","Wentt"],address,phone_number)

# #open up 3 bank accounts under user quai
# #open up 1 bank account under a random fake owner 
# quaiAccount1=Bank::Account.new("1234567",10000,DateTime.now,quai)
# quaiAccount2=Bank::Account.new("1234099",10,DateTime.now,quai)
# quaiAccount3=Bank::Account.new("1234901",100,DateTime.now,quai)
# otherAccount4=Bank::Account.new("1123290",100,DateTime.now,Bank::Owner.generate_fake_owner)

# #test the .accounts method it should print out all the ids of quaiAccounts1-3 
# puts "To test .accounts method should print ids: 1234567,1234099, and 1234901"
# quai.accounts.each do |account|
# 	puts account.id
# end


# #this should print out all of the ids including the one owned by fake owner
# puts "To test .all and .accounts. This should print all ids of bank accounts"
# Bank::Account.all.each do |account|
# 	puts account.id
# end

#To Test Savings account
# save_quai = Bank::SavingsAccount.new("1234567",1201,DateTime.now,quai)
# #puts save_quai.balance
# # save_quai2 = Bank::SavingsAccount.new("7654321",1,DateTime.now,quai)
# # puts save_quai2.balance
# puts save_quai.withdraw(1)
# puts save_quai.withdraw(1)
# puts save_quai.add_interest_rate(0.25)
# puts save_quai.balance

#To test Checking Acount
# ch_quai = Bank::CheckingAccount.new("1234567",1201,DateTime.now,quai)
# puts ch_quai.withdraw(1)
# puts ch_quai.withdraw(100)
# puts ch_quai.withdraw(1)
# puts ch_quai.withdraw(1100)
# puts ch_quai.withdraw_using_check(1100)

#To Test Money Market Account
mm=Bank::MoneyMarketAccount.new("1234567",1000000,DateTime.now,quai)
puts mm.balance.to_money

puts mm.withdraw(100).to_money #transaction 1
puts mm.withdraw(100).to_money	#this transaction didn't go through

puts mm.deposit(100).to_money #transaction 2

puts mm.deposit(10100).to_money 

puts mm.transactions
puts mm.add_interest_rate(0.25).to_money
puts mm.balance.to_money







