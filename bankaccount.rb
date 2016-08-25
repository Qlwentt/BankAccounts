require 'Faker'
require 'csv'
#require 'awesome_print'
require 'time'

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
			
			#probably need to make a separate method for this...
			CSV.open("current_owners.csv","a") do |csv|
				@@owners.each do |owner|
					csv<<[owner.id,owner.name.last,owner.name.first,owner.address[:street1],owner.address[:city],owner.address[:state],owner.phone_number]
				end
			end
		end

		def self.create_from_csv(csv_name)
			owners_csv=CSV.open(csv_name,'r')
			owners_csv.shift
			
			owners_csv.each do |row|
				Bank::Owner.new(row[0],row[1],row[2],row[3])
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


			puts "You have a new bank account with id: #{@id} balance: $#{balance}"
			
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
			if potential_balance<0
				puts "Sorry, this withdrawl will cause the account to have a negative balance. Your current balance is: $#{@balance/100.0} please try again."
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




#make a fake version of me (an owner) using address and phone number from faker
#fake_name=[Faker::Name.first_name,Faker::Name.last_name]
address={street1:Faker::Address.street_address, street2: "", city: Faker::Address.city, state: Faker::Address.state, zip:Faker::Address.zip}
phone_number=Faker::PhoneNumber.phone_number
quai=Bank::Owner.new("3333333",["Quai","Wentt"],address,phone_number)

#open up 3 bank accounts under user quai
#open up 1 bank account under a random fake owner 
quaiAccount1=Bank::Account.new("1234567",10000,DateTime.now,quai)
quaiAccount2=Bank::Account.new("1234099",10,DateTime.now,quai)
quaiAccount3=Bank::Account.new("1234901",100,DateTime.now,quai)
otherAccount4=Bank::Account.new("1123290",100,DateTime.now,Bank::Owner.generate_fake_owner)

#test the .accounts method it should print out all the ids of quaiAccounts1-3 
puts "To test .accounts method should print ids: 1234567,1234099, and 1234901"
quai.accounts.each do |account|
	puts account.id
end


#this should print out all of the ids including the one owned by fake owner
puts "To test .all and .accounts. This should print all ids of bank accounts"
Bank::Account.all.each do |account|
	puts account.id
end












