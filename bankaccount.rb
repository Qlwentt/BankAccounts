require 'Faker'
require 'csv'
require 'awesome_print'



#ask why I can't refer to a variable when I'm trying to make a default
#value for a paramater
module Bank
	class Owner
		@@owners=[]
		attr_accessor :name, :address, :phone_number
		
		def initialize(name=[Faker::Name.first_name,Faker::Name.last_name],address={street1:Faker::Address.street_address, street2: "", city: Faker::Address.city, state: Faker::Address.state, zip:Faker::Address.zip},phone_number=phone_number=Faker::PhoneNumber.phone_number)
			@name=name #array of first name, last name
			@address=address #hash of address line 1, line 2
			@phone_number=phone_number
		end

		def self.create_from_csv(csv_name)
		end

		def self.all
			return @@owners
		end

		def self.find(id)
		end
	end

	class Account
		
		@@used_ids=[]
		@@accounts=[]
		attr_reader :balance, :id, :open_date, :owner
		
		def initialize(id,balance,open_date,owner)
			raise ArgumentError, "You cannot open a bank account with a negative balance" unless balance.to_i>0
			@balance=balance.to_i
			#@id=generate_id
			@id=id
			@open_date=open_date#DateTime.now
			@owner=owner
			puts "You have a new bank account with id: #{@id} balance: $#{balance}"
			
		end

		# def self.create_from_csv(csv_name)
		# 	accounts_csv=CSV.open(csv_name,'r')
		# 	accounts_csv.shift
		# 	accounts_csv.each do |row|
		# 		@@accounts << Bank::Account.new(row[0],row[1],row[2],Bank::Owner.new)
		# 	end
		# end

		# def self.all 
		# 	return @@accounts
		# end

		# def self.find(id)
		# 	#probably can do @@accounts here
		# 	self.all.each do |account|
		# 		if account.id==id
		# 			puts account.id
		# 			puts account
		# 			return account
		# 		end
		# 	end
		# 	puts "Could not find a bank account with id: #{id}"
		# end

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
			if potential_balance<0
				puts "Sorry, this withdrawl will cause the account to have a negative balance. Your current balance is: $#{@balance} please try again."
				return balance
			else
				return @balance-=amount
			end
		end

		def deposit(amount)
			return @balance+=amount
		end
	end
	
	
end

fake_name=[Faker::Name.first_name,Faker::Name.last_name]
address={street1:Faker::Address.street_address, street2: "", city: Faker::Address.city, state: Faker::Address.state, zip:Faker::Address.zip}
phone_number=Faker::PhoneNumber.phone_number
quai=Bank::Owner.new(fake_name,address,phone_number)

account=Bank::Account.new("1234567","500","2016-08-23T13:08:23-07:00",quai)

#Bank::Account.create_from_csv('bankdata.csv')

# Bank::Account.all.each do |this_account|     
# 	puts "Name:
# #{this_account.owner.name}\nID:#{this_account.id}\nBalance: #{this_account.balance} " #
# end

# puts Bank::Account.all
# puts Bank::Account.find("7022235").balance
# puts Bank::Account.find("00").balance

# my_account=Bank::Account.new(quai,300) # my_account.withdraw(301) #
# account2=Bank::Account.new(quai,80000) # account2.deposit(40)


# CSV.open("bankdata.csv",'a') do |csv|
# 	csv<<[my_account.id,my_account.balance,my_account.open_date]
# 	csv<<[account2.id,account2.balance,account2.open_date]
# end
















